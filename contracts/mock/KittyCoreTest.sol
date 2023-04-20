// SPDX-License-Identifier: MIT
// Reference: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../ITokenURI.sol";

contract KittyCoreTest is ERC721, Ownable2Step {
    
    struct Kitty 
    {
        // The Kitty's genetic code is packed into these 256-bits, the format is
        // sooper-sekret! A cat's genes never change.
        uint256 genes;

        // The timestamp from the block when this cat came into existence.
        uint64 birthTime;

        // The minimum timestamp after which this cat can engage in breeding
        // activities again. This same timestamp is used for the pregnancy
        // timer (for matrons) as well as the siring cooldown.
        uint64 cooldownEndBlock;

        // The ID of the parents of this kitty, set to 0 for gen0 cats.
        // Note that using 32-bit unsigned integers limits us to a "mere"
        // 4 billion cats. This number might seem small until you realize
        // that Ethereum currently has a limit of about 500 million
        // transactions per year! So, this definitely won't be a problem
        // for several years (even as Ethereum learns to scale).
        uint32 matronId;
        uint32 sireId;

        // Set to the ID of the sire cat for matrons that are pregnant,
        // zero otherwise. A non-zero value here is how we know a cat
        // is pregnant. Used to retrieve the genetic material for the new
        // kitten when the birth transpires.
        uint32 siringWithId;

        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this Kitty. This starts at zero
        // for gen0 cats, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action, regardless
        // of whether this cat is acting as matron or sire.
        uint16 cooldownIndex;

        // The "generation number" of this cat. Cats minted by the CK contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other cats is the larger of the two generation
        // numbers of their parents, plus one.
        // (i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;
    }

    ITokenURI private _tokenURIContract;
    uint256 nextTop100Id;
    uint256 nextTop3000Id;

    mapping(uint256 => Kitty) internal _kitties; 
 
    constructor() ERC721("CryptoKittiesTest", "CK-TEST")
    {
        nextTop100Id = 1;
        nextTop3000Id = 101;
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

    function kittyIndexToApproved(uint256 id) public view returns (address) {
         return super.getApproved(id);
    }

    function transfer(address to, uint256 tokenId) external {
        transferFrom(msg.sender, to, tokenId);
    }

    /// @param _id The ID of the kitty of interest.
    function getKitty(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
        Kitty storage kit = _kitties[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (kit.siringWithId != 0);
        isReady = (kit.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(kit.cooldownIndex);
        nextActionAt = uint256(kit.cooldownEndBlock);
        siringWithId = uint256(kit.siringWithId);
        birthTime = uint256(kit.birthTime);
        matronId = uint256(kit.matronId);
        sireId = uint256(kit.sireId);
        generation = uint256(kit.generation);
        genes = kit.genes;
    }

    function mintGreaterThan3000(uint256 id_, uint16 generation_) external {
        require(id_ > 3000, "invalid id");
        _mintKitty(msg.sender, id_, generation_);
    }

    function mintTop100() external {
        require(nextTop100Id <= 100, "Top100 mint out");

        address to_ = msg.sender;
        uint256 id_ = nextTop100Id;
        nextTop100Id++;

         _mintKitty(to_, id_, 0);
    }

    function mintTop3000() external {
        require(nextTop3000Id <= 3000, "Top 3000 mint out");

        address to_ = msg.sender;
        uint256 id_ = nextTop3000Id;
        nextTop3000Id++;

         _mintKitty(to_, id_, 0);
    }

    function _mintKitty(
        address to_, 
        uint256 id_,
        uint16 generation
        ) internal {
        super._mint(to_, id_);

         Kitty storage kit = _kitties[id_];
         kit.generation = generation;
         kit.cooldownIndex = uint16(block.number % 14);
         kit.cooldownEndBlock = 0;
         kit.siringWithId = 0;
         kit.birthTime = uint64(block.timestamp);
         kit.genes = uint256(keccak256(abi.encode(block.number)));
    }
}
