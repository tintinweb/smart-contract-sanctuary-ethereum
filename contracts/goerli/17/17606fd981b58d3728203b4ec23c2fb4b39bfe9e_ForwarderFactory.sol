/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// File: contracts/CloneFactory.sol


// from https://github.com/optionality/clone-factory
pragma solidity 0.7.5;

/*
    The MIT License (MIT)
    Copyright (c) 2018 Murray Software, LLC.
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    function createClone(address target, bytes32 salt)
        internal
        returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(add(clone, 0x14), targetBytes)

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            result := create2(0, clone, 0x37, salt)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)

            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)

            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

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
        require(_newParent != address(0x0), "Cannot uninitialize forwarder");
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

// File: contracts/ForwarderFactory.sol


pragma solidity 0.7.5;



contract ForwarderFactory is CloneFactory {
    address public implementationAddress;

    event ForwarderCreated(address newForwarderAddress, address parentAddress);

    constructor(address _implementationAddress) {
        implementationAddress = _implementationAddress;
    }

    function generateForwarderAddress(address parent, bytes32 salt)
        external
        view
        returns (address)
    {
        require(parent != address(0x0), "Parent must not be 0 address");
        bytes32 finalSalt = keccak256(abi.encodePacked(parent, salt));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                finalSalt,
                keccak256(
                    abi.encodePacked(
                        // forwarder proxy contract bytecode (extracted from CloneFactory.sol)
                        0x3D602d80600A3D3981F3363d3d373d3D3D363d73,
                        implementationAddress,
                        bytes15(0x5af43d82803e903d91602b57fd5bf3)
                    )
                )
            )
        );

        return address(uint160(uint256(hash)));
    }

    function createForwarder(address parent, bytes32 salt) external {
        require(parent != address(0x0), "Parent must not be 0 address");

        bytes32 finalSalt = keccak256(abi.encodePacked(parent, salt));

        address payable clone = createClone(implementationAddress, finalSalt);
        Forwarder(clone).init(parent);
        emit ForwarderCreated(clone, parent);
    }
}