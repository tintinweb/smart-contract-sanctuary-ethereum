//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

contract RequireBlock {
    /**
     *GreaterThan:greater than
     *LessThan:less than
     *GreaterThanOrEqual:equal or greater than
     *LessThanOrEqual:equal or less than
     *Equal:equal
     *NotEqual:Not equal
     */
    enum Operator {
        GreaterThan,
        LessThan,
        GreaterThanOrEqual,
        LessThanOrEqual,
        Equal,
        NotEqual
    }

    enum CallWay {
        Call,
        StaticCall,
        Const
    }

    /// @notice core function Testing if the status is as expected
    /// @dev  can exec for anyone.
    /// @param expression The expression parameter is an expression encoding information that sets how A and B will be compared
    function exec(bytes calldata expression) external {
        //67 length
        require(expression.length > 47, "invalid length");
        //head
        uint8 op = uint8(expression[0]);
        uint8 wayA = uint8(expression[1]);
        uint8 wayB = uint8(expression[2]);
        require(wayA < 3 && wayB < 3 && op < 6, "invalid head");
        (bytes32 valueA, uint256 index) = _valueConv(expression, wayA, 3);

        (bytes32 valueB, uint256 end) = _valueConv(expression, wayB, index);

        require(end == expression.length, "invalid end");

        if (op == uint8(Operator.GreaterThan)) {
            require(valueA > valueB, "!>");
        } else if (op == uint8(Operator.LessThan)) {
            require(valueA < valueB, "!<");
        } else if (op == uint8(Operator.GreaterThanOrEqual)) {
            require(valueA >= valueB, "!>=");
        } else if (op == uint8(Operator.LessThanOrEqual)) {
            require(valueA <= valueB, "!<=");
        } else if (op == uint8(Operator.Equal)) {
            require(valueA == valueB, "!==");
        } else if (op == uint8(Operator.NotEqual)) {
            require(valueA != valueB, "!!=");
        }
    }

    ///expression->A/B Calculation results
    function _valueConv(
        bytes calldata expression,
        uint8 way,
        uint256 start
    ) private returns (bytes32 ret, uint256 index) {
        if (way == uint8(CallWay.Const)) {
            ret = bytes32(expression[start:start + 32]);

            index = start + 32;
        } else {
            address dst = address(bytes20(expression[start:start + 20]));

            index = start + 20;
            uint16 len = uint16(bytes2(expression[index:index + 2]));

            index += 2;
            bytes memory data = expression[index:index + len];

            index += len;
            bool success;
            bytes memory returndata;
            if (way == uint8(CallWay.Call)) {
                //solhint-disable avoid-low-level-calls
                (success, returndata) = dst.call{value: 0}(data);
            } else if (way == uint8(CallWay.StaticCall)) {
                //Compare user Eth balances
                if (dst == address(0)) {
                    address user = address(bytes20(data));
                    ret = bytes32(address(user).balance);
                    return (ret, index);
                }
                (success, returndata) = dst.staticcall(data);
            } else {
                revert("invalid way");
            }

            if (success) {
                if (returndata.length > 32) revert("invalid ret");
                ret = abi.decode(returndata, (bytes32));
            } else {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable reason-string
                if (returndata.length < 68) revert();
                // solhint-disable no-inline-assembly
                assembly {
                    returndata := add(returndata, 0x04)
                }
                revert(abi.decode(returndata, (string)));
            }
        }
    }
}