// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IBanana.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";

contract Banana is IBanana, Ownable {
    string public constant override name = "Banana";
    string public constant override symbol = "BANA";
    uint8 public constant override decimals = 18;
    
    address public override apeXToken;
    uint256 public override redeemTime;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    mapping(address => bool) public minters;
    mapping(address => bool) public burners;

    constructor(address apeXToken_, uint256 redeemTime_) {
        owner = msg.sender;
        apeXToken = apeXToken_;
        redeemTime = redeemTime_;
    }

    function updateRedeemTime(uint256 redeemTime_) external onlyOwner {
        require(redeemTime_ > block.timestamp, "need over current time");
        emit RedeemTimeChanged(redeemTime, redeemTime_);
        redeemTime = redeemTime_;
    }

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }

    function addBurner(address burner) external onlyOwner {
        burners[burner] = true;
    }

    function removeBurner(address burner) external onlyOwner {
        burners[burner] = false;
    }

    function mint(address to, uint256 apeXAmount) external override returns (uint256) {
        require(minters[msg.sender], "forbidden");
        require(apeXAmount > 0, "zero amount");

        uint256 apeXBalance = IERC20(apeXToken).balanceOf(address(this));
        uint256 mintAmount;
        if (totalSupply == 0) {
            mintAmount = apeXAmount * 1000;
        } else {
            mintAmount = apeXAmount * 1000 * totalSupply / apeXBalance;
        }

        TransferHelper.safeTransferFrom(apeXToken, msg.sender, address(this), apeXAmount);
        _mint(to, mintAmount);
        emit Mint(to, apeXAmount, mintAmount);
        return mintAmount;
    }

    function burn(address from, uint256 amount) external override returns (bool) {
        require(burners[msg.sender], "forbidden");
        require(amount <= totalSupply, "amount > totalSupply");
        _burn(from, amount);
        emit Burn(from, amount);
        return true;
    }

    function redeem(uint256 amount) external override returns (uint256) {
        require(block.timestamp >= redeemTime, "unredeemable");
        require(balanceOf[msg.sender] >= amount, "not enough balance");

        uint256 totalApeX = IERC20(apeXToken).balanceOf(address(this));
        uint256 apeXAmount = amount * totalApeX / totalSupply / 1000;

        _burn(msg.sender, amount);
        TransferHelper.safeTransfer(apeXToken, msg.sender, apeXAmount);

        emit Redeem(msg.sender, amount, apeXAmount);
        return apeXAmount;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "transfer amount exceeds allowance");
            allowance[from][msg.sender] = currentAllowance - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(balanceOf[from] >= value, "balance of from < value");
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) private {
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= value, "transfer amount exceeds balance");
        balanceOf[from] = fromBalance - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

interface IBanana is IERC20 {
    event RedeemTimeChanged(uint256 oldRedeemTime, uint256 newRedeemTime);
    event Mint(address indexed to, uint256 apeXAmount, uint256 mintAmount);
    event Burn(address indexed from, uint256 amount);
    event Redeem(address indexed user, uint256 burntAmount, uint256 apeXAmount);

    function apeXToken() external view returns (address);
    function redeemTime() external view returns (uint256);

    function mint(address to, uint256 apeXAmount) external returns (uint256);
    function burn(address from, uint256 value) external returns (bool);
    function redeem(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}