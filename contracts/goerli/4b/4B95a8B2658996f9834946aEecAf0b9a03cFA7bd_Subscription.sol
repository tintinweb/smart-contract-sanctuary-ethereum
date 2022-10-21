/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

//ERC20 interface
interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface PriceFeed {
    function price(string memory symbol) external view returns (uint256);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Subscription {
    using SafeMath for uint256;

    mapping(address => User) public users;

    struct User {
        address tokenStaked;
        uint256 expiryDate;
    }

    // PriceFeed public priceFeed =
    //     PriceFeed(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1); //ETH Mainnet

    function subscribe(address token) external {
        //uint256 tokenPrice = priceFeed.price(IERC20(token).symbol());

        // console.log("Token Price is :", tokenPrice);

        //uint8 decimals = IERC20(token).decimals();

        //console.log("Decimals are: ", decimals);

        // uint256 tokens = SafeMath.mul(
        //     SafeMath.div(SafeMath.mul(50, 10**decimals), tokenPrice),
        //     10**6
        // );

        // console.log(
        //     "Token Price In USD Is : ",
        //     SafeMath.div(tokenPrice, 10**6)
        // );

        //console.log("Tokens To Send Are : ", tokens);

        require(
            IERC20(token).transferFrom(msg.sender, address(this), 50 * 10**6),
            "Transfer Failed"
        );

        uint256 expiryDate = block.timestamp + 1 days;

        User memory usr;

        usr.tokenStaked = token;
        usr.expiryDate = expiryDate;

        users[msg.sender] = usr;
    }

    function getUser() external view returns (User memory) {
        return users[msg.sender];
    }

    function checkMembership() external view returns (bool) {

        if (users[msg.sender].expiryDate < block.timestamp) {
            return false;
        } else {
            return true;
        }
    }
}