// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IKittyCore.sol";
import "./ITokenURI.sol";

contract WrappedGen0CryptoKitties is ERC721, Ownable2Step, ReentrancyGuard {
        
    ITokenURI private _tokenURIContract;

    IKittyCore public kittyCore;

    address royaltyReceiver;

    // royalty fee = price * royaltyFee / 1000
    uint256 royaltyFee;

 
    constructor(address kittyCore_) ERC721("Wrapped Gen0 CryptoKitties", "WrapG0")
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
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (
        address receiver_,
        uint256 royaltyAmount_){

        receiver_ = royaltyReceiver;
        royaltyAmount_ = _salePrice * royaltyFee / 1000;                   
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

    function batchWrap(uint256[] calldata kittyIds_) external nonReentrant {        
        for(uint i = 0; i < kittyIds_.length; i++){
            uint256 kittyId = kittyIds_[i];
            _wrap(kittyId);
        }
    }

    function batchUnWrap(uint256[] calldata kittyIds_) external nonReentrant {        
        for(uint i = 0; i < kittyIds_.length; i++){
            uint256 kittyId = kittyIds_[i];
            _unwrap(kittyId);
        }
    }

    function _unwrap(uint256 kittyId)  internal {
        require(msg.sender == ownerOf(kittyId),"not owner");                
        kittyCore.transfer(msg.sender, kittyId);
        _burn(kittyId);
    }

    function _wrap(uint256  kittyId) internal{        
        (,,,,,,,,uint256 generation,) = kittyCore.getKitty(kittyId);
        require(msg.sender == kittyCore.ownerOf(kittyId), 'not owner');
        require(kittyCore.kittyIndexToApproved(kittyId) == address(this), 'you must approve() to WG0CK contract');
        require(generation == 0, 'this kitty must be Gen0');
        kittyCore.transferFrom(msg.sender, address(this), kittyId);
        _mint(msg.sender, kittyId);
    }
}
