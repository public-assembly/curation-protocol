// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("Mock NFT", "MOCK") {}

    uint256 tokenId = 0;

    function mint(address _to) public {
        _mint(_to, ++tokenId);
    }

    function emitTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        emit Transfer(_from, _to, _tokenId);
    }
}
