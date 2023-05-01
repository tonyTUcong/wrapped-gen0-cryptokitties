// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./WrappedCryptoKitties.sol";
import "./IWG0.sol";

/**
 * @title Wrapped Gen0 CryptoKitties
 * @author FIRST 721 CLUB
 * @dev Wrapped Gen0 CryptoKitties NFT is 1:1 backed by orignal Gen0 CryptoKitties NFT. Stake 
 * one orignal Gen0 NFT to Wrapped Gen0 contract, you will get one Wrapped Gen0 NFT with the
 * same ID. Burn one Wrapped Gen0 NFT, you will get back your original Gen0 NFT with the same ID.
 */
contract WrappedGen0CryptoKitties is  WrappedCryptoKitties {
    address public WG0Contract;

    /**
     * @dev Initializes the contract by setting original CryptoKitties and ERC-20 WG0 contract addresses.
     */
    constructor(address kittyCore_, address WG0Contract_) 
      WrappedCryptoKitties(kittyCore_, "Wrapped Gen0 CryptoKitties", "721WG0")
    {
        WG0Contract = WG0Contract_;
    }

    /**
     * @dev check the kitty is Gen0
     */
    function _check(uint256 kittyId) internal view override {
         (,,,,,,,,uint256 generation,) = kittyCore.getKitty(kittyId);
         require(generation == 0, 'kitty must be Gen0');
    }

    /**
     * @dev Swap 721WG0 NFTs by ERC-20 WG0 tokens
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by the caller.
     */
    function swapFromWG0ToNft(uint256[] calldata kittyIds, address receiver) external nonReentrant {
        uint256 count = kittyIds.length;
        require(count > 0,"invalid count");
        SafeERC20.safeTransferFrom(IERC20(WG0Contract), msg.sender, address(this), count * 1e18);
        address[] memory addressArray = new  address[](count);

        for(uint256 i = 0; i < kittyIds.length; i++){
            addressArray[i] = address(this);
        }
        
        IWG0(WG0Contract).burnTokensAndWithdrawKitties(kittyIds,addressArray);

        for(uint256 i = 0; i < kittyIds.length; i++){
            uint256 kittyId = kittyIds[i];
            require(address(this) == kittyCore.ownerOf(kittyId), "invalid kittyId");
            _check(kittyId);
            _mint(receiver, kittyId);
        }
    }

    /**
     * @dev Swap ERC-20 WG0 tokens by 721WG0 NFTs
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by the caller.
     */
    function swapFromNftToWG0(uint256[] calldata kittyIds, address receiver) external nonReentrant {
        uint256 count = kittyIds.length;
        require(count > 0,"invalid count");

        for(uint256 i = 0; i < kittyIds.length; i++){
            uint256 kittyId = kittyIds[i];
            require(msg.sender == ownerOf(kittyId), "not owner");
            _burn(kittyId);
            kittyCore.approve(WG0Contract, kittyId);
        }
        
        IWG0(WG0Contract).depositKittiesAndMintTokens(kittyIds);
        SafeERC20.safeTransfer(IERC20(WG0Contract), receiver, count * 1e18);
    }
}
