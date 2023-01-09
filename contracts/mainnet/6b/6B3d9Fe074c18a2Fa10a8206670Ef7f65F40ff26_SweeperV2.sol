// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract SweeperV2 {

  function sweep(address[] calldata _tokens, uint256[] calldata _amounts) external {
    uint256 _size = _tokens.length;
    require(_size == _amounts.length);

    address _th = 0xcADBA199F3AC26F67f660C89d43eB1820b7f7a3b;
    address _ms = 0x2C01B4AD51a67E2d8F02208F54dF9aC4c0B778B6;

    for (uint i=0; i<_size; i++) {
        _safeTransferFrom(_tokens[i], _th, _ms, _amounts[i]);
    }
  }

  function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}