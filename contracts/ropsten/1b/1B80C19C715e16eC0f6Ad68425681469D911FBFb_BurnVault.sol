// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

interface IBurnableERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function burn(uint256 amount) external;
}

contract Administrable {

    address[] public admins;

    address public owner;

    modifier onlyAdmin {
        require(isAdmin(msg.sender), "Administrable: caller is not an admin");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Administrable: caller is not the deployer");
        _;
    }

    constructor() {
        admins.push(msg.sender);
        owner = msg.sender;
    }

    function addAdmin(address newAdmin) external onlyOwner {
        require(!isAdmin(newAdmin));
        admins.push(newAdmin);
    }

    function removeAdmin(address adminToRemove) external onlyOwner {
        for(uint256 k = 0; k < admins.length; k++) {
            if (adminToRemove == admins[k]) {
                removeAtIndex(k);
                return;
            }
        }
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    function removeAtIndex(uint256 index) internal {
        require(index < admins.length, "Index invalid");
        admins[index] = admins[admins.length - 1];
        admins.pop();
    }

    function isAdmin(address addr) public view returns (bool wasAdmin) {
        for (uint256 k = 0; k < admins.length; k++) {
            if (admins[k] == addr) {
                return true;
            }
        }
        return false;
    }

    function getAdminAtIndex(uint256 index) public view returns (address admin) {
        require(index < admins.length, "Index invalid");
        return admins[index];
    }

}

contract BurnVault is Administrable {

    address[] public burnableTokens;

    constructor() {
    }

    function burnAll() external {
        for (uint256 k = 0; k < burnableTokens.length; k++) {
            burnTokenAtIndex(k);
        }
    }
  
    function burnTokenAtIndex(uint256 index) public {
        IBurnableERC20 tokenToBurn = IBurnableERC20(burnableTokens[index]);
        uint256 balance = tokenToBurn.balanceOf(address(this));
        
        tokenToBurn.burn(balance);
    }

    function addToken(address tokenAddr) external onlyOwner {
        for (uint256 k = 0; k < burnableTokens.length; k++) {
            require(tokenAddr != burnableTokens[k]);
        }
        burnableTokens.push(tokenAddr);
    }

    function removeToken(address tokenAddr) external onlyOwner {
        for (uint256 k = 0; k < burnableTokens.length; k++) {
            if (burnableTokens[k] == tokenAddr) {
                burnableTokens[k] = burnableTokens[burnableTokens.length - 1];
                burnableTokens.pop();
            }
        }
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "external call failed");
        return result;
    }

}