// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

interface IBadgeRenderer {
    // function drawSVGToString(bytes memory data)
    //     external
    //     view
    //     returns (string memory);

    // function drawSVGToBytes(bytes memory data)
    //     external
    //     view
    //     returns (bytes memory);

    function tokenURI(uint256 id) external view returns (string memory);
}
