// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IKittyCore {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function transfer(address to, uint256 tokenId) external;
    /**
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
    )
    */
    function getKitty(uint256 id) external view returns (bool,bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function kittyIndexToApproved(uint256 id) external view returns (address);
}
