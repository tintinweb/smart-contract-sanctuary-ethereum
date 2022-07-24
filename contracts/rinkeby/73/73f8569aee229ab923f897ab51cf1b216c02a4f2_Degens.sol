//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract Degens is ERC721A {

    address public manager;

    bool public state = false;
    uint256 public amountPerWallet = 1;
    uint256 public totalAmount = 5;
    string private _baseTokenURI = 'https://ikzttp.mypinata.cloud/ipfs/QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/';

    constructor() ERC721A("Degens", "Degens") {
        manager = msg.sender;
    }

    function mint() external payable {
        require(state == true, 'Mint not live');
        require(_numberMinted(msg.sender) < amountPerWallet, 'cannot mint more than 3');
        require(_totalMinted() < totalAmount, 'Cannot mint more than total amount');

        _mint(msg.sender, 1);
    }

    function flipState() public onlyManager {
        state = !state;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyManager {
        _baseTokenURI = baseURI;
    }
}