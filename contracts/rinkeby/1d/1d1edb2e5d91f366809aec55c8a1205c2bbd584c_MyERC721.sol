// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./MyERC20.sol";

contract MyERC721 {
    string public name;
    string public symbol;
    address public erc20;
    uint256 public maxSupply;
    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOfAsset;

    constructor(
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _maxSupply
    ) {
        name = _name;
        symbol = _symbol;
        erc20 = _erc20;
        maxSupply = _maxSupply;
        totalSupply = 0; //should be 0 by default, just in case...
    }

    function mint() public {
        require(totalSupply < maxSupply, "No NFT left");
        require(
            getERC20Bal() > 10,
            "Not enough ERC20 tokens to be able to mint"
        );
        ownerOfAsset[totalSupply] = msg.sender;
        totalSupply++;
    }

    function transfer(address to, uint256 assetId) public {
        require(ownerOfAsset[assetId] == msg.sender);
        ownerOfAsset[assetId] = to;
    }

    function getERC20Bal() public view returns (uint256) {
        MyERC20 erc20Contract = MyERC20(erc20);
        return erc20Contract.balanceOf(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Source: https://ethereum.org/en/developers/tutorials/understand-the-erc-20-token-smart-contract/

contract MyERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _total
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _total;
        _balances[msg.sender] = _total;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return _balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public {
        require(numTokens <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender] - numTokens;
        _balances[receiver] = _balances[receiver] + numTokens;
    }
}