/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

contract BlueExecutor {
    address private immutable owner;
    address public immutable factory;
    address public immutable WETH9;
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + 3;


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _factory, address _WETH9) public payable {
        owner = msg.sender;
        factory = _factory;
        WETH9 = _WETH9;
    }

    receive() external payable {
    }


    function computeAddress(address factory, address token0, address token1, uint24 fee) internal pure returns (address pool) {
        require(token0 < token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(token0, token1, fee)),
                        bytes32(0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54)
                    )
                )
            )
        );
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        address token0 = toAddress(_data, 0);
        uint24 fee = toUint24(_data, ADDR_SIZE);
        address token1 = toAddress(_data, NEXT_OFFSET);
        address pool = computeAddress(factory, token0, token1, fee);
        require(msg.sender == address(pool));

        if (amount0Delta > 0) {
            (bool _success, bytes memory _response) = token0.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), msg.sender, uint256(amount0Delta)));
            require(_success);
        } else if (amount1Delta > 0) {
            (bool _success, bytes memory _response) = token1.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), msg.sender, uint256(amount1Delta)));
            require(_success);
        }
    }

    function call2(uint256 _ethAmountToCoinbase, address[] memory _targets, uint256[] memory _values, bytes[] memory _payloads) external onlyOwner payable {
        require (_targets.length == _payloads.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, ) = _targets[i].call{value: _values[i]}(_payloads[i]);
            require(_success);
        }

        if (_ethAmountToCoinbase == 0) return;
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}