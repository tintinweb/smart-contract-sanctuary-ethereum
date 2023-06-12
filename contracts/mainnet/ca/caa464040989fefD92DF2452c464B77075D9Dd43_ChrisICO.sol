/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

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

contract ChrisICO is Ownable {
    using SafeMath for uint256;
    IERC20 TKIT_token;
    uint public startTime;
    uint public endTime;
    uint public presaleRate;
    uint public hardCap;
    uint public fundRaised;
    uint private constant MAX_BPS = 10000;
    address public TKIT;
    address[] public allBuyerAddress;

    struct TokenSale {
        uint soldToken;
        uint tokenForSale;
    }
    TokenSale public tokenSale;

    struct UserInfo {
        uint TKIT_Token;
        uint investDollar;
    }
    mapping(address => UserInfo) public userInfo;

    enum currencyType {
        native,
        token
    }

    constructor(address _TKIT, uint _startTime, uint _endTime) {
        require(
            _endTime > _startTime,
            "End Time should be greater than Start Time"
        );
        require(
            _startTime > block.timestamp,
            "Start time should be greater than current time"
        );
        TKIT = _TKIT;
        TKIT_token = IERC20(TKIT);
        startTime = _startTime;
        endTime = _endTime;

        presaleRate = 666667; // 0.00666667 * 100000000  8 zeroes
        tokenSale.tokenForSale = 562500000 * 10 ** TKIT_token.decimals(); //562500000
        hardCap = tokenSale.tokenForSale;
    }

    //==================================================================================

    ///@dev any investor can call this function
    function buy(
        uint256 _dollar,
        currencyType CurrencyType,
        address _tokenContractAddress,
        uint _tokenValue
    ) public payable returns (bool) {
        uint256 buyToken = ((_dollar * 10 ** TKIT_token.decimals()) * MAX_BPS) /
            presaleRate;

        //ICO should be running
        require(isICOOver() == false, "ICO already end");

        //Cannot call this function before start time of ICO
        require(block.timestamp >= startTime, "Out of time window");

        //There should be enough JIOCHAIN tokens for sale
        require(tokenSale.tokenForSale >= buyToken, "No enough token for sale");

        if (userInfo[msg.sender].TKIT_Token == 0) {
            userInfo[msg.sender] = UserInfo(buyToken, _dollar);
            allBuyerAddress.push(msg.sender);
        } else {
            userInfo[msg.sender].TKIT_Token += buyToken;
            userInfo[msg.sender].investDollar += _dollar;
        }

        if (CurrencyType == currencyType.native) {
            require(
                msg.value == _tokenValue,
                "Msg.value should be equal to token value"
            );
            payable(owner()).call{value: msg.value};
        } else {
            IERC20(_tokenContractAddress).transferFrom(
                msg.sender,
                owner(),
                _tokenValue
            );
        }

        //transfer the TKIT token to investor who is calling the buy function
        TKIT_token.transfer(msg.sender, buyToken);

        //subtracts the value in the token for sale amount
        tokenSale.tokenForSale -= buyToken;

        //adds the value in the sold token amount
        tokenSale.soldToken += buyToken;

        //adds the value to fund raised in dollar
        fundRaised += _dollar;

        return true;
    }

    //=========================================Admin Functions===========================

    ///@dev only owner(admin)of ICO can call this function
    ///@dev should be called when ICO ends for leftover tokens
    function retrieveStuckedERC20Token() public onlyOwner returns (bool) {
        TKIT_token.transfer(owner(), TKIT_token.balanceOf(address(this)));
        return true;
    }

    ///@dev only owner(admin)of ICO can call this function
    ///@dev owner can update the start and end time of the ICO
    ///@dev owner can only call this function before ICO starts
    function updateTime(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner returns (bool) {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            startTime > block.timestamp,
            "Can not change time after ICO starts"
        );

        startTime = _startTime;
        endTime = _endTime;
        return true;
    }

    ///@dev only owner(admin)of ICO can call this function
    ///@dev admin can airdrop to any wallet address by calling this function
    ///@dev _to give wallet address and in _amount givr how much amount admin want to airdrop
    function airDrop(address _to, uint256 _amount) public onlyOwner {
        TKIT_token.transfer(_to, _amount);
    }

    //==================================================================================

    ///@dev gives information whether ICO is over or not
    ///@dev if it returns true that means ICO is over oterwise not
    ///@dev if time crosses the end time or hard cap is reach then it will return true
    function isICOOver() public view returns (bool) {
        if (block.timestamp > endTime || tokenSale.tokenForSale == 0) {
            return true;
        } else {
            return false;
        }
    }

    ///@dev gives information whether Hard cap of ICO reaced or not
    ///@dev if hard cap is reached then it will return true
    function isHardCapReach() public view returns (bool) {
        if (hardCap == tokenSale.soldToken) {
            return true;
        } else {
            return false;
        }
    }

    //==================================================================================
}