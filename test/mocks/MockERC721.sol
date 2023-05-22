// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "thirdweb-contracts/eip/ERC721A.sol";

contract MockERC721 is ERC721A {
    constructor() ERC721A("MockERC721", "M721") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }
}
