/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface erc20 {
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
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

interface fee_dist {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
    function commit_admin(address) external;
    function apply_admin() external;
}

contract ib_burner {
    resolver constant addresses = resolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    synthetix public snx;

    curve constant curve_eur = curve(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859);
    curve constant curve_aud = curve(0x3F1B0278A9ee595635B61817630cC19DE792f506);
    curve constant curve_chf = curve(0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c);
    curve constant curve_gbp = curve(0xD6Ac1CB9019137a896343Da59dDE6d097F710538);
    curve constant curve_jpy = curve(0x8818a9bb44Fbf33502bE7c15c500d0C783B73067);
    curve constant curve_krw = curve(0x8461A004b50d321CB22B7d034969cE6803911899);

    address constant ib_eur = address(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27);
    address constant ib_aud = address(0xFAFdF0C4c1CB09d430Bf88c75D88BB46DAe09967);
    address constant ib_chf = address(0x1CC481cE2BD2EC7Bf67d1Be64d4878b16078F309);
    address constant ib_gbp = address(0x69681f8fde45345C3870BCD5eaf4A05a60E7D227);
    address constant ib_jpy = address(0x5555f75e3d5278082200Fb451D1b6bA946D8e13b);
    address constant ib_krw = address(0x95dFDC8161832e4fF7816aC4B6367CE201538253);

    address constant s_eur = address(0xD71eCFF9342A5Ced620049e616c5035F1dB98620);
    address constant s_aud = address(0xF48e200EAF9906362BB1442fca31e0835773b8B4);
    address constant s_chf = address(0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d);
    address constant s_gbp = address(0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F);
    address constant s_jpy = address(0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d);
    address constant s_krw = address(0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B);

    address constant msig = address(0x0D5Dc686d0a2ABBfDaFDFb4D0533E886517d4E83);
    fee_dist constant dist = fee_dist(0xB9d18ab94cf61bB2Bcebe6aC8Ba8c19fF0CDB0cA);

    function commit_admin(address _addr) external {
        require(msg.sender == msig);
        dist.commit_admin(_addr);
    }

    function apply_admin() external {
        require(msg.sender == msig);
        dist.apply_admin();
    }

    constructor() {
        erc20(ib_aud).approve(address(curve_aud), type(uint).max);
        erc20(ib_chf).approve(address(curve_chf), type(uint).max);
        erc20(ib_gbp).approve(address(curve_gbp), type(uint).max);
        erc20(ib_jpy).approve(address(curve_jpy), type(uint).max);
        erc20(ib_krw).approve(address(curve_krw), type(uint).max);

        snx = synthetix(addresses.getAddress("Synthetix"));

        erc20(s_aud).approve(address(snx), type(uint).max);
        erc20(s_chf).approve(address(snx), type(uint).max);
        erc20(s_gbp).approve(address(snx), type(uint).max);
        erc20(s_jpy).approve(address(snx), type(uint).max);
        erc20(s_krw).approve(address(snx), type(uint).max);

        erc20(s_eur).approve(address(curve_eur), type(uint).max);
    }

    function update_snx() external {
        snx = synthetix(addresses.getAddress("Synthetix"));

        erc20(s_aud).approve(address(snx), type(uint).max);
        erc20(s_chf).approve(address(snx), type(uint).max);
        erc20(s_gbp).approve(address(snx), type(uint).max);
        erc20(s_jpy).approve(address(snx), type(uint).max);
        erc20(s_krw).approve(address(snx), type(uint).max);
    }

    // converts all profits from non eur based tokens to sEUR
    function exchanger() external {
        _exchange(ib_aud, "sAUD", curve_aud);
        _exchange(ib_chf, "sCHF", curve_chf);
        _exchange(ib_gbp, "sGBP", curve_gbp);
        _exchange(ib_jpy, "sJPY", curve_jpy);
        _exchange(ib_krw, "sKRW", curve_krw);
    }

    // convert sEUR to ibEUR and distribute
    function distribute_no_checkpoint() external {
        uint amount = erc20(s_eur).balanceOf(address(this));
        if (amount > 0) {
            curve_eur.exchange(1, 0, amount, 0, address(this));
        }
        erc20(ib_eur).transfer(address(dist), erc20(ib_eur).balanceOf(address(this)));
    }

    // convert sEUR to ibEUR and distribute
    function distribute() external {
        uint amount = erc20(s_eur).balanceOf(address(this));
        if (amount > 0) {
            curve_eur.exchange(1, 0, amount, 0, address(this));
        }
        erc20(ib_eur).transfer(address(dist), erc20(ib_eur).balanceOf(address(this)));
        dist.checkpoint_token();
        dist.checkpoint_total_supply();
    }

    function _exchange(address ib, bytes32 s, curve c) internal {
        uint amount = erc20(ib).balanceOf(address(this));
        if (amount > 0) {
            uint amountReceived = c.exchange(0, 1, amount, 0, address(this));
            if (amountReceived > 0) {
                snx.exchangeWithTracking(s, amountReceived, "sEUR", address(this), "ibAMM");
            }
        }
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