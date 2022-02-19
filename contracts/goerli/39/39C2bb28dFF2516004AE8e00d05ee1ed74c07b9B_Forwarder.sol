/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// File: contracts/ERC20Interface.sol


pragma solidity 0.7.5;

abstract contract ERC20Interface {
    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);
}

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

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
            'TransferHelper::safeApprove: approve failed'
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
            'TransferHelper::safeTransfer: transfer failed'
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
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts/Forwarder.sol


pragma solidity 0.7.5;



contract Forwarder {
    address public parentAddress;
    event ForwarderDeposited(address from, uint256 value, bytes data);

    event ParentSwitched(address currentParent, address newParent);

    function init(address _parentAddress) external onlyUninitialized {
        parentAddress = _parentAddress;

        uint256 value = address(this).balance;

        if (value == 0) {
            return;
        }

        (bool success, ) = parentAddress.call{value: value}("");
        require(success, "Flush failed");
        emit ForwarderDeposited(address(this), value, msg.data);
    }

    modifier onlyParent() {
        require(msg.sender == parentAddress, "Only Parent");
        _;
    }

    modifier onlyUninitialized() {
        require(parentAddress == address(0x0), "Already initialized");
        _;
    }

    function setParent(address _newParent) external onlyParent {
        require(_newParent != address(0x0), "Cannot uninitialize Forwarder");
        address _currentParent = parentAddress;
        parentAddress = _newParent;
        emit ParentSwitched(_currentParent, _newParent);
    }

    fallback() external payable {
        flush();
    }

    receive() external payable {
        flush();
    }

    function flushTokens(address tokenContractAddress) external onlyParent {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        address forwarderAddress = address(this);
        uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
        if (forwarderBalance == 0) {
            return;
        }

        TransferHelper.safeTransfer(
            tokenContractAddress,
            parentAddress,
            forwarderBalance
        );
    }

    function flush() public {
        uint256 value = address(this).balance;

        if (value == 0) {
            return;
        }

        (bool success, ) = parentAddress.call{value: value}("");
        require(success, "Flush failed");
        emit ForwarderDeposited(msg.sender, value, msg.data);
    }
}