// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// Code source : https://etherscan.io/address/0x25c7b64a93eb1261e130ec21a3e9918caa38b611#code

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../IKittyCore.sol";

/// @title Main contract for Wrapped VG0. This contract converts Virgin Gen 0 Cryptokitties between the ERC721 standard 
///  and the ERC20 standard by locking cryptokitties into the contract and minting 1:1 backed ERC20 tokens, that
///  can then be redeemed for cryptokitties when desired. This concept originated with WCK (Wrapped Cryptokitties).
///  This code is only a very slight modification of the original contract; It simply adds the Gen 0 requirement, 
///	 the fast cooldown requirement, and the getKitty interfacing.
///
/// @notice When wrapping a cryptokitty, you get a generic WVG0 token. Since the WVG0 token is generic, it has no
///  no information about what cryptokitty you submitted, so you will most likely not receive the same kitty
///  back when redeeming the token unless you specify that kitty's ID. The token only entitles you to receive 
///  *a* cryptokitty in return, not necessarily the *same* cryptokitty in return. A different user can submit
///  their own WVG0 tokens to the contract and withdraw the kitty that you originally deposited. WVG0 tokens have
///  no information about which kitty was originally deposited to mint WVG0 - this is due to the very nature of 
///  the ERC20 standard being fungible, and the ERC721 standard being nonfungible.
contract WVG0Test is ERC20, ReentrancyGuard {


    /* ****** */
    /* EVENTS */
    /* ****** */

    /// @dev This event is fired when a user deposits cryptokitties into the contract in exchange
    ///  for an equal number of WVG0 ERC20 tokens.
    /// @param kittyId  The cryptokitty id of the kitty that was deposited into the contract.
    event DepositKittyAndMintToken(
        uint256 kittyId
    );

    /// @dev This event is fired when a user deposits WVG0 ERC20 tokens into the contract in exchange
    ///  for an equal number of locked cryptokitties.
    /// @param kittyId  The cryptokitty id of the kitty that was withdrawn from the contract.
    event BurnTokenAndWithdrawKitty(
        uint256 kittyId
    );

    /* ******* */
    /* STORAGE */
    /* ******* */

    /// @dev An Array containing all of the cryptokitties that are locked in the contract, backing
    ///  WVG0 ERC20 tokens 1:1
    /// @notice Some of the kitties in this array were indeed deposited to the contract, but they
    ///  are no longer held by the contract. This is because withdrawSpecificKitty() allows a 
    ///  user to withdraw a kitty "out of order". Since it would be prohibitively expensive to 
    ///  shift the entire array once we've withdrawn a single element, we instead maintain this 
    ///  mapping to determine whether an element is still contained in the contract or not. 
    uint256[] private depositedKittiesArray;

    /// @dev A mapping keeping track of which kittyIDs are currently contained within the contract.
    /// @notice We cannot rely on depositedKittiesArray as the source of truth as to which cats are
    ///  deposited in the contract. This is because burnTokensAndWithdrawKitties() allows a user to 
    ///  withdraw a kitty "out of order" of the order that they are stored in the array. Since it 
    ///  would be prohibitively expensive to shift the entire array once we've withdrawn a single 
    ///  element, we instead maintain this mapping to determine whether an element is still contained 
    ///  in the contract or not. 
    mapping (uint256 => bool) private kittyIsDepositedInContract;


    IKittyCore kittyCore;


    /// @notice The owner is not capable of changing the address of the CryptoKitties Core
    ///  contract once the contract has been deployed.
    constructor(address kittyCore_) ERC20("Wrapped Virgin Gen0", "WVG0") {
        kittyCore = IKittyCore(kittyCore_);
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /// @notice Allows a user to lock cryptokitties in the contract in exchange for an equal number
    ///  of WG0 ERC20 tokens.
    /// @param _kittyIds  The ids of the cryptokitties that will be locked into the contract.
    /// @notice The user must first call approve() in the Cryptokitties Core contract on each kitty
    ///  that thye wish to deposit before calling depositKittiesAndMintTokens(). There is no danger 
    ///  of this contract overreaching its approval, since the CryptoKitties Core contract's approve() 
    ///  function only approves this contract for a single Cryptokitty. Calling approve() allows this 
    ///  contract to transfer the specified kitty in the depositKittiesAndMintTokens() function.
    function depositKittiesAndMintTokens(uint256[] calldata _kittyIds) external nonReentrant {        
        require(_kittyIds.length > 0, 'you must submit an array with at least one element');
        for(uint i = 0; i < _kittyIds.length; i++){
            uint256 kittyToDeposit = _kittyIds[i];

            uint256 kittyCooldown;
            uint256 kittyGen;
            
            (,,kittyCooldown,,,,,,kittyGen,) = kittyCore.getKitty(kittyToDeposit);

            require(msg.sender == kittyCore.ownerOf(kittyToDeposit), 'you do not own this cat');
            require(kittyCore.kittyIndexToApproved(kittyToDeposit) == address(this), 'you must approve() this contract before you can deposit a cat');
            require(kittyGen == 0, 'this cat must be generation 0');
            require(kittyCooldown == 0, 'cooldown must be fast');


            kittyCore.transferFrom(msg.sender, address(this), kittyToDeposit);
            _pushKitty(kittyToDeposit);
            emit DepositKittyAndMintToken(kittyToDeposit);
        }
        _mint(msg.sender, _kittyIds.length * (10**18));
    }

    /// @notice Allows a user to burn WVG0 ERC20 tokens in exchange for an equal number of locked 
    ///  cryptokitties.
    /// @param _kittyIds  The IDs of the kitties that the user wishes to withdraw. If the user submits 0 
    ///  as the ID for any kitty, the contract uses the last kitty in the array for that kitty.
    /// @param _destinationAddresses  The addresses that the withdrawn kitties will be sent to (this allows 
    ///  anyone to "airdrop" kitties to addresses that they do not own in a single transaction).
    function burnTokensAndWithdrawKitties(uint256[] calldata _kittyIds, address[] calldata _destinationAddresses) external nonReentrant {
        require(_kittyIds.length == _destinationAddresses.length, 'you did not provide a destination address for each of the cats you wish to withdraw');
        require(_kittyIds.length > 0, 'you must submit an array with at least one element');

        uint256 numTokensToBurn = _kittyIds.length;
        require(balanceOf(msg.sender) >= numTokensToBurn * (10**18), 'you do not own enough tokens to withdraw this many ERC721 cats');
        _burn(msg.sender, numTokensToBurn * (10**18));
        
        for(uint i = 0; i < numTokensToBurn; i++){
            uint256 kittyToWithdraw = _kittyIds[i];
            if(kittyToWithdraw == 0){
                kittyToWithdraw = _popKitty();
            } else {
                require(kittyIsDepositedInContract[kittyToWithdraw] == true, 'this kitty has already been withdrawn');
                require(address(this) == kittyCore.ownerOf(kittyToWithdraw), 'the contract does not own this cat');
                kittyIsDepositedInContract[kittyToWithdraw] = false;
            }
            kittyCore.transfer(_destinationAddresses[i], kittyToWithdraw);
            emit BurnTokenAndWithdrawKitty(kittyToWithdraw);
        }
    }

    /// @notice Adds a locked cryptokitty to the end of the array
    /// @param _kittyId  The id of the cryptokitty that will be locked into the contract.
    function _pushKitty(uint256 _kittyId) internal {
        depositedKittiesArray.push(_kittyId);
        kittyIsDepositedInContract[_kittyId] = true;
    }

    /// @notice Removes an unlocked cryptokitty from the end of the array
    /// @notice The reason that this function must check if the kittyIsDepositedInContract
    ///  is that the withdrawSpecificKitty() function allows a user to withdraw a kitty
    ///  from the array out of order.
    /// @return  The id of the cryptokitty that will be unlocked from the contract.
    function _popKitty() internal returns(uint256){
        require(depositedKittiesArray.length > 0, 'there are no cats in the array');
        uint256 kittyId = depositedKittiesArray[depositedKittiesArray.length - 1];
        depositedKittiesArray.pop();
        while(kittyIsDepositedInContract[kittyId] == false){
            kittyId = depositedKittiesArray[depositedKittiesArray.length - 1];
            depositedKittiesArray.pop();
        }
        kittyIsDepositedInContract[kittyId] = false;
        return kittyId;
    }

    /// @notice Removes any kitties that exist in the array but are no longer held in the
    ///  contract, which happens if the first few kitties have previously been withdrawn 
    ///  out of order using the withdrawSpecificKitty() function.
    /// @notice This function exists to prevent a griefing attack where a malicious attacker
    ///  could call withdrawSpecificKitty() on a large number of kitties at the front of the
    ///  array, causing the while-loop in _popKitty to always run out of gas.
    /// @param _numSlotsToCheck  The number of slots to check in the array.
    function batchRemoveWithdrawnKittiesFromStorage(uint256 _numSlotsToCheck) external {
        require(_numSlotsToCheck <= depositedKittiesArray.length, 'you are trying to batch remove more slots than exist in the array');
        uint256 arrayIndex = depositedKittiesArray.length;
        for(uint i = 0; i < _numSlotsToCheck; i++){
            arrayIndex = arrayIndex - 1;
            uint256 kittyId = depositedKittiesArray[arrayIndex];
            if(kittyIsDepositedInContract[kittyId] == false){
                depositedKittiesArray.pop();
            } else {
                return;
            }
        }
    }

}
