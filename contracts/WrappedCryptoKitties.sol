// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IKittyCore.sol";
import "./ITokenURI.sol";

/**
 * @title Wrapped CryptoKitties
 * @author FIRST 721 CLUB
 * @dev Wrapped  CryptoKitties NFT is 1:1 backed by orignal CryptoKitties NFT. Stake one orignal NFT
 * to Wrapped contract, you will get one Wrapped NFT with the same ID. Burn one Wrapped NFT, you will
 * get back your original NFT with the same ID.
 */
contract WrappedCryptoKitties is ERC721, Ownable2Step, ReentrancyGuard {
        
    ITokenURI private _tokenURIContract;

    IKittyCore public kittyCore;

    address royaltyReceiver;

    // royalty fee = price * royaltyFee / 1000
    uint256 royaltyFee;

 
    constructor(address kittyCore_, string memory name_, string memory symbol_) ERC721(name_, symbol_)
    {
        kittyCore = IKittyCore(kittyCore_);
    }

    function setTokenURIContract(address tokenURIContract_) external onlyOwner {
        _tokenURIContract = ITokenURI(tokenURIContract_);
    }

    function getTokenURIContract() external view returns(address) {
        return address(_tokenURIContract);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return _tokenURIContract.tokenURI(tokenId);
    }

    // EIP-2981
    function royaltyInfo(uint256, uint256 salePrice) external view returns (
        address receiver,
        uint256 royaltyAmount){

        receiver = royaltyReceiver;
        royaltyAmount = salePrice * royaltyFee / 1000;
    }

    function updateRoyaltyInfo(address receiver_, uint256 royaltyFee_) external onlyOwner {
        royaltyReceiver = receiver_;
        royaltyFee = royaltyFee_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4  _INTERFACE_ID_ERC2981 = 0x2a55205a;
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function wrap(uint256  kittyId) external nonReentrant {
        _wrap(kittyId);
    }

    function unwrap(uint256  kittyId) external nonReentrant {
        _unwrap(kittyId);
    }

    function batchWrap(uint256[] calldata kittyIds) external nonReentrant {
        for(uint i = 0; i < kittyIds.length; i++){
            uint256 kittyId = kittyIds[i];
            _wrap(kittyId);
        }
    }

    function batchUnwrap(uint256[] calldata kittyIds) external nonReentrant {
        for(uint i = 0; i < kittyIds.length; i++){
            uint256 kittyId = kittyIds[i];
            _unwrap(kittyId);
        }
    }

    function _unwrap(uint256 kittyId)  internal {
        require(msg.sender == ownerOf(kittyId),"not owner");
        kittyCore.transfer(msg.sender, kittyId);
        _burn(kittyId);
    }

    function _wrap(uint256  kittyId) internal {        
        require(msg.sender == kittyCore.ownerOf(kittyId), 'not owner');
        require(kittyCore.kittyIndexToApproved(kittyId) == address(this), 'not approve');
        _check(kittyId);
        kittyCore.transferFrom(msg.sender, address(this), kittyId);
        _mint(msg.sender, kittyId);
    }

    function _check(uint256  kittyId)  internal view virtual {}
}
