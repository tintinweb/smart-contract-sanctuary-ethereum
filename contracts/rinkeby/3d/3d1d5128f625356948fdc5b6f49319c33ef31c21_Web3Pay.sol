// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";


contract Web3Pay is ContextUpgradeSafe, ReentrancyGuardUpgradeSafe, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 internal constant _feeTo_           = "feeTo";
    bytes32 internal constant _remainRatio_     = "remainRatio";

    function __Web3Pay_init() external initializer {
        __Context_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Governable_init_unchained(_msgSender());
        __Web3Pay_init_unchained();
    }

    function __Web3Pay_init_unchained() internal initializer {
        config[_feeTo_      ]   = uint(_msgSender());
        config[_remainRatio_]   = 0.998e18;                         // 99.8%, feeRate = 0.2%
    }

    function pay(PermitSign calldata ps, address token, address payable to, uint amount, bytes32 orderId) nonReentrant payable external {
        address sender = _msgSender();
        uint rr = getConfigA(_remainRatio_, to);
        if(rr == 0)
            rr = config[_remainRatio_];
        require(rr <= 1e18, "Invalid remainRatio");
        uint remain = amount.mul(rr).div(1e18);
        uint fee = amount.sub(remain);
        address payable feeTo = address(config[_feeTo_]);
        if(token == address(0)) {                   // ETH
            require(amount == msg.value, "not match amount and msg.value");
            to.transfer(remain);
            if(fee > 0)
                feeTo.transfer(fee);
        } else {
            _permit(sender, ps, token, amount);
            if(fee > 0) {
                IERC20(token).transferFrom(sender, address(this), amount);
                IERC20(token).transfer(to, remain);
                IERC20(token).transfer(feeTo, fee);
            } else
                IERC20(token).transferFrom(sender, to, amount);
        }
        emit Paid(sender, token, to, amount, uint(1e18).sub(rr), orderId);
    }
    event Paid(address indexed sender, address indexed token, address indexed to, uint amount, uint feeRate, bytes32 orderId);

    function _permit(address sender, PermitSign calldata ps, address token, uint amount) internal {
        if(ps.v != 0 || ps.r != 0 || ps.s != 0)
            if(ps.allowed)
                IPermitAllowed(token).permit(sender, address(this), IPermitAllowed(token).nonces(sender), ps.deadline, true, ps.v, ps.r, ps.s);
            else
                ERC20Permit(token).permit(sender, address(this), amount, ps.deadline, ps.v, ps.r, ps.s);
    }
}

interface IPermitAllowed {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address holder) external view returns (uint);
}

struct PermitSign {
    bool    allowed;
    uint32  deadline;
    uint8   v;
    bytes32 r;
    bytes32 s;
}