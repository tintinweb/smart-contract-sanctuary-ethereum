// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IERC20.sol";
import "../interfaces/IENCTR.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/ITreasury.sol";

import "../types/EncountrAccessControlled.sol";

import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";

contract EncountrPresale is EncountrAccessControlled {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event SaleStarted(uint256 tokenPrice, IERC20 purchaseToken);
    event SaleEnded();
    event BuyerApproved(address indexed buyer);

    ITreasury public treasury;
    IERC20 public purchaseToken;
    IERC20 public enctr;

    uint256 public min;
    uint256 public max;
    uint256 public price;

    mapping(address => bool) public allowed;
    mapping(address => uint256) public orderSize;

    // If both are false, the nothing can be done other than buyer approval. This will be the case
    // before the sale has started.
    // If active is true but finished is false, then the sale is ongoing and people can make their
    // orders.
    // It finished is true but active is false, the sale is over and people can claim their tokens.
    // It should not be the case that _both_ are true.
    bool public active; // Is the sale running?
    bool public finished; // Has the sale finished?

    constructor(
        address _authority,
        address _treasury,
        uint256 _min,
        uint256 _max,
        address _purchaseToken,
        address _enctr,
        uint256 _price
    ) EncountrAccessControlled(IEncountrAuthority(_authority)) {
        require(_authority != address(0), "zero address.");

        require(_treasury != address(0), "zero address.");
        treasury = ITreasury(_treasury);

        require(_purchaseToken != address(0), "zero address.");
        purchaseToken = IERC20(_purchaseToken);
        require(_enctr != address(0), "zero address.");
        enctr = IENCTR(_enctr);

        require(_max > _min, "min is higher than max.");
        min = _min;
        max = _max;

        require(_price >= 10**IERC20Metadata(address(purchaseToken)).decimals(), "need ENCTR backing");
        price = _price;
    }

    function start() external onlyGovernor() {
        require(!finished, "this sale has already finished.");
        active = true;
        emit SaleStarted(price, purchaseToken);
    }

    function stop() external onlyGovernor() {
        require(active, "this sale has already stopped.");
        active = false;
    }

    function finish() external onlyGovernor() {
        require(!active, "this sale is ongoing.");
        finished = true;
        emit SaleEnded();
    }

    function _approveBuyer(address _buyer) internal {
        allowed[_buyer] = true;
        emit BuyerApproved(_buyer);
    }

    function approveBuyer(address _buyer) external onlyGovernor() {
        _approveBuyer(_buyer);
    }

    function approveBuyers(address[] calldata _newBuyers) external onlyGovernor() {
        for(uint256 i = 0; i < _newBuyers.length; i++) {
            _approveBuyer(_newBuyers[i]);
        }
    }

    function _buyFromTreasury(address _buyer, uint256 _amountOfEnctr) internal {
        (uint256 totalPrice, uint256 decimals) = _totalPrice(_amountOfEnctr);
        purchaseToken.safeApprove(address(treasury), totalPrice);
        treasury.deposit(
            totalPrice,
            address(purchaseToken),
            totalPrice.div(10**decimals).sub(_amountOfEnctr)
        );

        enctr.safeTransfer(_buyer, _amountOfEnctr);
    }

    function _totalPrice(uint256 _amountOfEnctr) public view returns (uint256 _amount, uint256 _decimals) {
        _decimals = IERC20Metadata(address(enctr)).decimals();
        _amount = price.mul(_amountOfEnctr).div(10**_decimals);
    }

    function buy(uint256 _amountOfEnctr) external {
        require(active, "sale is not active");
        require(allowed[msg.sender], "buyer not approved");

        uint256 size = orderSize[msg.sender];
        uint256 total = size + _amountOfEnctr;
        require(total >= min, "below minimum for sale.");
        require(total <= max, "above maximum for sale.");

        (uint256 totalPrice,) = _totalPrice(_amountOfEnctr);
        purchaseToken.safeTransferFrom(msg.sender, address(this), totalPrice);
        orderSize[msg.sender] = total;
    }

    function _claim(address _buyer) internal {
        require(finished, "this sale is not been finalized.");
        require(orderSize[_buyer] > 0, "this address has not ordered.");
        _buyFromTreasury(_buyer, orderSize[_buyer]);
        orderSize[_buyer] = 0;
    }

    function claim() external {
        _claim(msg.sender);
    }

    function batchClaim(address[] calldata _buyers) external {
        for(uint256 i = 0; i < _buyers.length; i++) {
            _claim(_buyers[i]);
        }
    }

    function refund() external {
        uint256 size = orderSize[msg.sender];
        require(size > 0, "nothing to refund.");
        (uint256 totalPrice,) = _totalPrice(size);
        purchaseToken.safeTransfer(msg.sender, totalPrice);
        orderSize[msg.sender] = 0;
    }

    function withdrawTokens(address _tokenToWithdraw) external onlyGovernor() {
        IERC20(_tokenToWithdraw).transfer(msg.sender, IERC20(_tokenToWithdraw).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IENCTR is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);

    function isPermitted(uint _status, address _address) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IEncountrAuthority.sol";

abstract contract EncountrAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IEncountrAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IEncountrAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IEncountrAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IEncountrAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
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
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IEncountrAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}