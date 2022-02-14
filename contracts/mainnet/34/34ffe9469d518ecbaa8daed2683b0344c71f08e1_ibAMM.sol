/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface erc20 {
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface synthetix {
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived);
}

interface resolver {
    function getAddress(bytes32) external view returns (address);
}

interface exchanger {
    function getAmountsForAtomicExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
    external
    view
    returns (
        uint amountReceived,
        uint fee,
        uint exchangeFeeRate
    );
}

interface curve {
    function get_dy(int128, int128, uint) external view returns (uint);
    function exchange(int128, int128, uint, uint, address) external returns (uint);
}

contract ibAMM {
    resolver constant addresses = resolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    curve constant eur = curve(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859);

    address susd = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    address ibeur = address(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27);
    address seur = address(0xD71eCFF9342A5Ced620049e616c5035F1dB98620);

    constructor() {
        erc20(ibeur).approve(address(eur), type(uint).max);
        erc20(seur).approve(address(eur), type(uint).max);
    }

    function quote_snx(uint amount) external view returns (uint amountReceived) {
        exchanger _exchange = exchanger(addresses.getAddress("Exchanger"));
        (amountReceived,,) = _exchange.getAmountsForAtomicExchange(amount, "sUSD", "sEUR");
    }

    // Quote susd to ibeur
    function quote_out(uint amount) external view returns (uint amountReceived) {
        exchanger _exchange = exchanger(addresses.getAddress("Exchanger"));
        (uint _out,,) = _exchange.getAmountsForAtomicExchange(amount, "sUSD", "sEUR");
        return eur.get_dy(1, 0, _out);
    }

    // Quote ibeur to susd
    function quote_in(uint amount) external view returns (uint amountReceived) {
        exchanger _exchange = exchanger(addresses.getAddress("Exchanger"));
        uint _out = eur.get_dy(0, 1, amount);
        (amountReceived,,) = _exchange.getAmountsForAtomicExchange(_out, "sEUR", "sUSD");
    }
    
    // Trade susd to ibeur
    function swap_out(uint amount, uint minOut) external returns (uint amountReceived) {
        _safeTransferFrom(susd, msg.sender, address(this), amount);
        synthetix _snx = synthetix(addresses.getAddress("Synthetix"));
        erc20(susd).approve(address(_snx), amount);
        amountReceived = _snx.exchangeAtomically("sUSD", amount, "sEUR", "ibAMM");
        amountReceived = eur.exchange(1, 0, amountReceived, minOut, msg.sender);
    }
    
    // Trade ibeur to susd
    function swap_in(uint amount, uint minOut) external returns (uint amountReceived) {
        _safeTransferFrom(ibeur, msg.sender, address(this), amount);
        amountReceived = eur.exchange(0, 1, amount, 0, address(this));
        synthetix _snx = synthetix(addresses.getAddress("Synthetix"));
        erc20(seur).approve(address(_snx), amountReceived);
        amountReceived = _snx.exchangeAtomically("sEUR", amountReceived, "sUSD", "ibAMM");
        require(amountReceived > minOut, "slippage");
        _safeTransfer(susd, msg.sender, amountReceived);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}