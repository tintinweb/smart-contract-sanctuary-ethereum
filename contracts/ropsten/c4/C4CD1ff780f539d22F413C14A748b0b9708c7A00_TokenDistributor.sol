// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract TokenDistributor is Administrable {

    struct Allocation {
        address account;
        uint256 points;
    }

    uint256 public MAX_POINTS = 10_000;

    address[] public distributableTokens;
    Allocation[] public allocations;
    uint256 public totalPoints = 0;

    constructor(address[] memory accounts, uint256[] memory points) {
        require(accounts.length > 0);
        require(points.length > 0);
        require(accounts.length == points.length);
        distributableTokens.push(address(0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1));
        for (uint256 a = 0; a < accounts.length; a++) {
            allocations.push(Allocation({
                account: accounts[a],
                points: points[a]
            }));
            totalPoints += points[a];
        }
    }

    function distributeAllTokens() external {
        for (uint256 k = 0; k < distributableTokens.length; k++) {
            distributeTokenAtIndex(k);
        }
    }
  
    function distributeTokenAtIndex(uint256 index) public {
        IERC20 tokenToDistribute = IERC20(distributableTokens[index]);
        uint256 balance = tokenToDistribute.balanceOf(address(this));
        for (uint256 a = 0; a < allocations.length; a++) {
            tokenToDistribute.transfer(allocations[a].account, balance * allocations[a].points / totalPoints);
        }
    }

    function addToken(address tokenAddr) external onlyOwner {
        for (uint256 k = 0; k < distributableTokens.length; k++) {
            require(tokenAddr != distributableTokens[k]);
        }
        distributableTokens.push(tokenAddr);
    }

    function removeToken(address tokenAddr) external onlyOwner {
        for (uint256 k = 0; k < distributableTokens.length; k++) {
            if (distributableTokens[k] == tokenAddr) {
                distributableTokens[k] = distributableTokens[distributableTokens.length - 1];
                distributableTokens.pop();
            }
        }
    }

    function addAllocation(address account, uint256 points) external onlyOwner {
        uint256 newTotalPoints = totalPoints + points;
        require(newTotalPoints < MAX_POINTS, "Too Many Allocation Points!");
        allocations.push(Allocation({
            account: account,
            points: points
        }));
        totalPoints = newTotalPoints;
    }

    function removeAllocation(address account) external onlyOwner {
        for (uint256 a = 0; a < allocations.length; a++) {
            if (allocations[a].account == account) {
                totalPoints -= allocations[a].points;
                allocations[a] = Allocation(account, 0);
                return;
            }
        }
    }

    function setAllocationPoints(address account, uint256 points) external onlyOwner {
        for (uint256 a = 0; a < allocations.length; a++) {
            if (allocations[a].account == account) {
                uint256 newTotalPoints = totalPoints - allocations[a].points + points;
                require(newTotalPoints < MAX_POINTS, "Too Many Allocation Points!");
                totalPoints = newTotalPoints;
                allocations[a].points = points;
            }
        }
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "external call failed");
        return result;
    }

}