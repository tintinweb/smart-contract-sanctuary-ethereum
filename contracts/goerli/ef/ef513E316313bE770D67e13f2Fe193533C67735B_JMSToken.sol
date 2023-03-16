/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JMSToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    string public logoURI;
    mapping(address => uint256) balances;
    address owner;
    bool public mintingAllowed = true;
    bool public burningAllowed = true;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        name = "JMS Token";
        symbol = "JMS";
        decimals = 18;
        totalSupply = 100000 * 10 ** uint256(decimals);
        logoURI = "ipfs://QmWPoZibaHQ4R6t2zEbBbqg5brg3WgLSB5Jn6P6XkTRmtm";
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balances[msg.sender] >= _amount, "Not enough balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(balances[_from] >= _amount, "Not enough balance");
        require(msg.sender == owner, "Only owner can transfer from");
        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function mint(address _account, uint256 _amount) public onlyOwner {
        require(mintingAllowed, "Minting is not allowed");
        require(_account != address(0), "Cannot mint to zero address");
        totalSupply += _amount;
        balances[_account] += _amount;
        emit Mint(_account, _amount);
    }
    
    function burn(uint256 _amount) public {
        require(burningAllowed, "Burning is not allowed");
        require(balances[msg.sender] >= _amount, "Not enough balance");
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        emit Burn(msg.sender, _amount);
    }
    
    function disableMinting() public onlyOwner {
        mintingAllowed = false;
    }
    
    function disableBurning() public onlyOwner {
        burningAllowed = false;
    }
    
    function setLogoURI(string memory _logoURI) public onlyOwner {
        logoURI = _logoURI;
    }
    
    function getTokenURI() public view returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", getTokenMetadata()));
    }
    
    function getTokenMetadata() internal view returns (string memory) {
        string memory json = string(abi.encodePacked(
            '{',
                '"name":"', name, '",',
                '"symbol":"', symbol, '",',
                '"decimals":', uint2str(decimals), ',',
                '"totalSupply":"', uint2str(totalSupply), '",',
                '"logoURI":"', logoURI, '"',
            '}'
        ));
        return json;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}