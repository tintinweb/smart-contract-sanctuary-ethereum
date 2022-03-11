/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface erc20 {
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface ibAMM {
    function repay(address cy, address token, uint amount) external returns (bool);
}

interface synthetix {
    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);
}

interface resolver {
    function getAddress(bytes32) external view returns (address);
}

interface curve {
    function get_dy(int128, int128, uint) external view returns (uint);
    function exchange(int128, int128, uint, uint, address) external returns (uint);
}


contract ib_settlement {
    resolver constant addresses = resolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    curve constant eur = curve(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859);

    address susd = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    address ibeur = address(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27);
    address seur = address(0xD71eCFF9342A5Ced620049e616c5035F1dB98620);
    ibAMM _ibAMM = ibAMM(0x8338Aa899fB3168598D871Edc1FE2B4F0Ca6BBEF);

    address msig = address(0x0D5Dc686d0a2ABBfDaFDFb4D0533E886517d4E83);
    
    function synth_exchange() external {
        uint amount = erc20(susd).balanceOf(address(this));
        synthetix _snx = synthetix(addresses.getAddress("Synthetix"));
        erc20(susd).approve(address(_snx), amount);
        _snx.exchangeWithTracking("sUSD", amount, "sEUR", address(this), "ibAMM");
    }

    function curve_exchange_and_repay() external {
        uint amount = erc20(seur).balanceOf(address(this));
        erc20(seur).approve(address(eur), amount);
        uint amountReceived = eur.exchange(1, 0, amount, 0, address(this));
        erc20(ibeur).approve(address(_ibAMM), amountReceived);
        _ibAMM.repay(0x00e5c0774A5F065c285068170b20393925C84BF3, ibeur, amountReceived);
    }

    function clawback(address token) external {
        require(msg.sender == msig);
        _safeTransfer(token, msig, erc20(token).balanceOf(address(this)));
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}