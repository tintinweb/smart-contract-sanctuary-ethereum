/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
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
pragma solidity 0.8.19;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity 0.8.19;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity 0.8.19;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
pragma solidity 0.8.19;
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}
pragma solidity 0.8.19;
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
pragma solidity 0.8.19;

contract SpaceXPepePresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    uint256[4] public rate;
    address public saleToken;
    uint public saleTokenDec;
    uint256 public totalTokensforSale;
    uint256 public maxBuyLimit;
    uint256 public minBuyLimit;
    mapping(address => bool) public tokenWL;
    mapping(address => uint256[4]) public tokenPrices;
    address[] public buyers;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    bool public isUnlockingStarted;
    mapping(address => BuyerTokenDetails) public buyersAmount;
    uint256 public totalTokensSold;
    Bounce[] public bounces;
    struct BuyerTokenDetails {
        uint amount;
        bool isClaimed;
    }
    struct Bounce {
        uint256 amount;
        uint256 percentage;
    }
    constructor() {}
    modifier isPresaleHasNotStarted() {
        if (presaleStartTime != 0) {
            require(
                block.timestamp < presaleStartTime,
                "Presale: Presale has already started"
            );
        }
        _;
    }
    modifier isPresaleStarted() {
        require(
            block.timestamp >= presaleStartTime,
            "Presale: Presale has not started yet"
        );
        _;
    }
    modifier isPresaleNotEnded() {
        require(block.timestamp < presaleEndTime, "Presale: Presale has ended");
        _;
    }
    modifier isPresaleEnded() {
        require(
            block.timestamp >= presaleEndTime,
            "Presale: Presale has not ended yet"
        );
        _;
    }
    event TokenAdded(address token, uint256[4] price);
    event TokenUpdated(address token, uint256[4] price);
    event TokensBought(
        address indexed buyer,
        address indexed token,
        uint256 amount,
        uint256 tokensBought
    );
    event TokensUnlocked(address indexed buyer, uint256 amount);
    event SaleTokenAdded(address token, uint256 amount);
    function setSaleTokenParams(
        address _saleToken,
        uint256 _totalTokensforSale
    ) external onlyOwner isPresaleHasNotStarted {
        require(
            _saleToken != address(0),
            "Presale: Sale token cannot be zero address"
        );
        require(
            _totalTokensforSale > 0,
            "Presale: Total tokens for sale cannot be zero"
        );
        saleToken = _saleToken;
        saleTokenDec = IERC20Metadata(saleToken).decimals();

        IERC20(saleToken).safeTransferFrom(
            msg.sender,
            address(this),
            _totalTokensforSale
        );
        totalTokensforSale = IERC20(saleToken).balanceOf(address(this));
        emit SaleTokenAdded(_saleToken, _totalTokensforSale);
    }
    function setPresaleTime(
        uint256 _presaleStartTime,
        uint256 _presaleEndTime
    ) external onlyOwner isPresaleHasNotStarted {
        require(
            _presaleStartTime < _presaleEndTime,
            "Presale: Start time must be less than end time"
        );
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
    }
    function addWhiteListedToken(
        address _token,
        uint256[4] memory _price
    ) external onlyOwner {
        tokenWL[_token] = true;
        tokenPrices[_token] = _price;
        emit TokenAdded(_token, _price);
    }
    function updateEthRate(uint256[4] memory _rate) external onlyOwner {
        rate = _rate;
    }
    function updateTokenRate(
        address _token,
        uint256[4] memory _price
    ) external onlyOwner {
        require(tokenWL[_token], "Presale: Token not whitelisted");
        tokenPrices[_token] = _price;
        emit TokenUpdated(_token, _price);
    }
    function startUnlocking() external onlyOwner isPresaleEnded {
        require(!isUnlockingStarted, "Presale: Unlocking has already started");
        isUnlockingStarted = true;
    }
    function stopUnlocking() external onlyOwner isPresaleEnded {
        require(isUnlockingStarted, "Presale: Unlocking hasn't started yet!");
        isUnlockingStarted = false;
    }
    function setBounces(
        uint256[] memory _amounts,
        uint256[] memory _percentages
    ) external onlyOwner {
        require(
            _amounts.length == _percentages.length,
            "Presale: Bounce arrays length mismatch"
        );
        for (uint256 i = 0; i < _percentages.length; i++) {
            require(
                _percentages[i] <= 1000,
                "Presale: Percentage should be less than 1000"
            );
        }
        delete bounces;
        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 min = i;
            for (uint256 j = i + 1; j < _amounts.length; j++) {
                if (_amounts[j] < _amounts[min]) {
                    min = j;
                }
            }
            uint256 temp = _amounts[min];
            _amounts[min] = _amounts[i];
            _amounts[i] = temp;

            temp = _percentages[min];
            _percentages[min] = _percentages[i];
            _percentages[i] = temp;

            bounces.push(Bounce(_amounts[i], _percentages[i]));
        }
    }
    function getCurrentTier() public view returns (uint) {
        uint256 duration = presaleEndTime - (presaleStartTime);

        if (block.timestamp <= presaleStartTime + (duration / (4))) {
            return 0;
        } else if (block.timestamp <= presaleStartTime + (duration / (2))) {
            return 1;
        } else if (block.timestamp <= presaleStartTime + ((duration * 3) / 4)) {
            return 2;
        } else {
            return 3;
        }
    }
    function getTokenAmount(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 amtOut;
        uint tier = getCurrentTier();
        if (token != address(0)) {
            require(tokenWL[token], "Presale: Token not whitelisted");

            amtOut = tokenPrices[token][tier] != 0
                ? (amount * (10 ** saleTokenDec)) / (tokenPrices[token][tier])
                : 0;
        } else {
            amtOut = rate[tier] != 0
                ? (amount * (10 ** saleTokenDec)) / (rate[tier])
                : 0;
        }
        return amtOut;
    }

    function getBounceAmount(uint256 amount) public view returns (uint256) {
        uint256 bounce = 0;
        for (uint256 i = 0; i < bounces.length; i++) {
            if (amount >= bounces[i].amount) {
                bounce = bounces[i].percentage;
            }
        }
        return (amount * bounce) / 1000;
    }
    function buyToken(
        address _token,
        uint256 _amount
    ) external payable isPresaleStarted isPresaleNotEnded {
        uint256 saleTokenAmt = _token != address(0)
            ? getTokenAmount(_token, _amount)
            : getTokenAmount(address(0), msg.value);
        require(
            saleTokenAmt >= minBuyLimit,
            "Presale: Min buy limit not reached"
        );
        require(
            buyersAmount[msg.sender].amount + saleTokenAmt <= maxBuyLimit,
            "Presale: Max buy limit reached for this phase"
        );
        require(
            (totalTokensSold + saleTokenAmt) <= totalTokensforSale,
            "Presale: Total Token Sale Reached!"
        );

        if (_token != address(0)) {
            require(_amount > 0, "Presale: Cannot buy with zero amount");
            require(tokenWL[_token], "Presale: Token not whitelisted");

            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        saleTokenAmt = saleTokenAmt + (getBounceAmount(saleTokenAmt));

        totalTokensSold += saleTokenAmt;
        buyersAmount[msg.sender].amount += saleTokenAmt;

        emit TokensBought(msg.sender, _token, _amount, saleTokenAmt);
    }

    function withdrawToken() external {
        require(isUnlockingStarted, "Presale: Locking period not over yet");

        require(
            !buyersAmount[msg.sender].isClaimed,
            "Presale: Already claimed"
        );

        uint256 tokensforWithdraw = buyersAmount[msg.sender].amount;
        buyersAmount[msg.sender].isClaimed = true;
        IERC20(saleToken).safeTransfer(msg.sender, tokensforWithdraw);

        emit TokensUnlocked(msg.sender, tokensforWithdraw);
    }

    function setMinBuyLimit(uint _minBuyLimit) external onlyOwner {
        minBuyLimit = _minBuyLimit;
    }

    function setMaxBuyLimit(uint _maxBuyLimit) external onlyOwner {
        maxBuyLimit = _maxBuyLimit;
    }

    function withdrawSaleToken(
        uint256 _amount
    ) external onlyOwner isPresaleEnded {
        IERC20(saleToken).safeTransfer(msg.sender, _amount);
    }

    function withdrawAllSaleToken() external onlyOwner isPresaleEnded {
        uint256 amt = IERC20(saleToken).balanceOf(address(this));
        IERC20(saleToken).safeTransfer(msg.sender, amt);
    }

    function withdraw(address token, uint256 amt) public onlyOwner {
        require(
            token != saleToken,
            "Presale: Cannot withdraw sale token with this method, use withdrawSaleToken() instead"
        );
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function withdrawAll(address token) public onlyOwner {
        require(
            token != saleToken,
            "Presale: Cannot withdraw sale token with this method, use withdrawAllSaleToken() instead"
        );
        uint256 amt = IERC20(token).balanceOf(address(this));
        withdraw(token, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
}