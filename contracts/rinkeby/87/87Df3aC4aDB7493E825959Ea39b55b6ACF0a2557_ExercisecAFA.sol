// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IAFA.sol";
import "./interfaces/IERC20Metadata.sol";

contract ExercisecAFA {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Exercise(address user, uint256 amount);
    event NewTerm(address vester, uint256 max, uint256 rate);

    address public owner;
    address public newOwner;

    address public immutable cAFA;
    address public immutable AFA;
    address public immutable USDT;
    address public immutable treasury;

    uint256 private immutable percentDenominator = 1_000_000;
    uint256 private rateMax = 140000;

    struct Term {
        uint256 percent; // (5000 = 0.5%), 5000/1000000
        uint256 claimed;
        uint256 max;
    }
    mapping(address => Term) public terms;

    mapping(address => address) public walletChange;

    constructor(
        address _cAFA,
        address _afa,
        address _usdc,
        address _treasury
    ) {
        owner = msg.sender;
        require(_cAFA != address(0));
        cAFA = _cAFA;
        require(_afa != address(0));
        AFA = _afa;
        require(_usdc != address(0));
        USDT = _usdc;
        require(_treasury != address(0));
        treasury = _treasury;
    }

    // Sets terms for a new wallet
    function setTerms(
        address _vester,
        uint256 _amountCanClaim,
        uint256 _rate
    ) external returns (bool) {
        require(msg.sender == owner, "Sender is not owner");
        require(
            _amountCanClaim >= terms[_vester].max,
            "cannot lower amount claimable"
        );
        require(_rate >= terms[_vester].percent, "cannot lower vesting rate");

        terms[_vester].max = _amountCanClaim;
        terms[_vester].percent = _rate;

        emit NewTerm(_vester, _amountCanClaim, _rate);

        return true;
    }

    // Allows wallet to redeem cAFA for AFA
    function exercise(uint256 _amount) external returns (bool) {
        Term memory info = terms[msg.sender];
        require(redeemable(info) >= _amount, "Not enough vested");
        require(info.max.sub(info.claimed) >= _amount, "Claimed over max");

        uint256 value = tokenAmountTo(USDT, _amount);
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), value);
        IAFA(cAFA).burnFrom(msg.sender, _amount);

        IERC20(USDT).approve(treasury, value);
        uint256 AFAToSend = ITreasury(treasury).deposit(value, USDT, 0);
        terms[msg.sender].claimed = info.claimed.add(_amount);
        IERC20(AFA).safeTransfer(msg.sender, AFAToSend);

        emit Exercise(msg.sender, _amount);

        return true;
    }

    function tokenAmountTo(address _token, uint256 _amount)
        public
        view
        returns (uint256 value_)
    {
        value_ = _amount
            .mul(10**IERC20Metadata(address(_token)).decimals())
            .div(10**IERC20Metadata(cAFA).decimals());
    }

    // Allows wallet owner to transfer rights to a new address
    function pushWalletChange(address _newWallet) external returns (bool) {
        require(terms[msg.sender].percent != 0);
        walletChange[msg.sender] = _newWallet;
        return true;
    }

    // Allows wallet to pull rights from an old address
    function pullWalletChange(address _oldWallet) external returns (bool) {
        require(walletChange[_oldWallet] == msg.sender, "wallet did not push");

        walletChange[_oldWallet] = address(0);
        terms[msg.sender] = terms[_oldWallet];
        delete terms[_oldWallet];

        return true;
    }

    function setRateMax(uint256 _rate) external returns (bool) {
        require(msg.sender == owner, "Sender is not owner");
        rateMax = _rate;
        return true;
    }

    // Amount a wallet can redeem based on current supply
    function redeemableFor(address _vester) public view returns (uint256) {
        return redeemable(terms[_vester]);
    }

    function redeemable(Term memory _info) internal view returns (uint256) {
        return
            IAFA(AFA)
                .totalSupply()
                .mul(rateMax)
                .div(percentDenominator)
                .mul(_info.percent)
                .div(percentDenominator)
                .sub(_info.claimed);
    }

    function pushOwnership(address _newOwner) external returns (bool) {
        require(msg.sender == owner, "Sender is not owner");
        require(_newOwner != address(0));
        newOwner = _newOwner;
        return true;
    }

    function pullOwnership() external returns (bool) {
        require(msg.sender == newOwner);
        owner = newOwner;
        newOwner = address(0);
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import './IERC20.sol';

interface IAFA is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

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
pragma solidity ^0.8.6;

import './IERC20.sol';

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(
        address _token,
        uint256 _amount,
        bool _withdraw
    ) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

import {IERC20} from '../interfaces/IERC20.sol';

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
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, to, amount));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'APPROVE_FAILED');
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, 'ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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