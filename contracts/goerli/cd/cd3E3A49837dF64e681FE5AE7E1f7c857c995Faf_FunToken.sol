/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

contract FunToken {
    string public name = "SPTOKEN";
    string public symbol = "SPVL";
    string public standard = "SPTOKEN v.0.1";
    uint256 public totalSupply;
    uint256 public _userId;

    address public ownerOfContract;

    address[] public holderToken;

    event Transfer(address indexed from, address indexed to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => TokenHolderInfo) public tokenHolderInfos;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    struct TokenHolderInfo {
        uint256 _tokenId;
        address _from;
        address _to;
        uint256 _totalToken;
        bool _tokenHolder;
    }

    constructor(uint256 _initialSupply) {
        ownerOfContract = msg.sender;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function inc() internal {
        _userId++;
    }

    function transfer(address to, uint256 value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= value);
        inc();
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        TokenHolderInfo storage tokenHolderInfo = tokenHolderInfos[to];
        tokenHolderInfo._to = to;
        tokenHolderInfo._from = msg.sender;
        tokenHolderInfo._totalToken = value;
        tokenHolderInfo._tokenHolder = true;
        tokenHolderInfo._tokenId = _userId;

        holderToken.push(to);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender,value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function getTokenHolderData(address _address)
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            bool
        )
    {
        return (
            tokenHolderInfos[_address]._tokenId,
            tokenHolderInfos[_address]._to,
            tokenHolderInfos[_address]._from,
            tokenHolderInfos[_address]._totalToken,
            tokenHolderInfos[_address]._tokenHolder
        );
    }

    function getTokenHolder() public view returns (address[] memory) {
        return holderToken;
    }
}