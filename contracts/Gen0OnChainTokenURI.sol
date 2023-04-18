// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ITokenURI.sol";
import "./IKittyCore.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Gen0OnChainTokenURI is ITokenURI {
    using Strings for uint256;

    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/-:# ";

    string[] private  _cooldownNames = ["Fast","Swift","Swift","Snappy","Snappy","Brisk","Brisk","Plodding","Plodding","Slow","Slow","Sluggish","Sluggish","Catatonic"];

    IKittyCore kittyCore;
    constructor(address kittyCore_)
    {
        kittyCore = IKittyCore(kittyCore_);
    }


    function tokenURI(uint256 tokenId) external view returns (string memory uri_) {
        (,,uint256 cooldownIndex,,,uint256 birthTime,,,uint256 generation,) = kittyCore.getKitty(tokenId);

        require(generation == 0, "generation is not zero");
        string memory verginity = cooldownIndex == 0 ?  "Vergin" : "Non-vergin";
        string memory fetureAndIdPrefix = '';
        if(tokenId <= 100) {
            fetureAndIdPrefix = '{"trait_type":"Feature","value":"Founder"},{"trait_type":"ID","value":';
        }
        else if(tokenId <= 3000) {
            fetureAndIdPrefix = '{"trait_type":"Feature","value":"Top3000"},{"trait_type":"ID","value":';
        }
        else {
            fetureAndIdPrefix = '{"trait_type":"ID","value":';
        }

        uri_ = 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                tokenId.toString(),
                                '","background_color":"ffffff","image":"',
                                getKittyImage(tokenId),
                                '","attributes":[{"trait_type":"Verginity","value":"',
                                verginity,
                                '"},{"trait_type":"Cooldown","value":"',
                                getCooldownName(cooldownIndex),
                                '"},{"display_type":"date","trait_type":"Birthday","value":',
                                birthTime.toString(),
                                '},',fetureAndIdPrefix, 
                                tokenId.toString(),
                                '}]}'
                            )
                        )
                    )
                )
            );
    }


    function getKittyImage(uint256 tokenId) public pure returns (string memory) {
       return string(abi.encodePacked("https://img.cryptokitties.co/0x06012c8cf97bead5deae237070f9587f8e7a266d/", tokenId.toString(),".png"));
    }
    
    function getCooldownName(uint256 cooldownIndex_) public view returns (string memory) {
        if(cooldownIndex_ <= 13) {
            return _cooldownNames[cooldownIndex_];
        }
        return "Unknown";
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = TABLE_ENCODE;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

