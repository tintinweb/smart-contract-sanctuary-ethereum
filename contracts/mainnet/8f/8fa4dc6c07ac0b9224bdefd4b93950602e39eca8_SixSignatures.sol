/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

/**

-----BEGIN PGP MESSAGE-----

hQEMA3mVM1kSdKslAQf+MefZejMJZUUHguc5SdipIjwuc7pphdfZBYRsEcuQso1F
nhEF0r5MlNKtbPMS7oJXLSX2cJO01SXAkWrs92mqx2+rgq8pyC2JLZq2BBQQgk6y
tnSyqqivbFqZbgD17D3h+O2grgRgbsUFX7YmgjM4Taewx9gDkpq77ezU14aKYUIC
psRbQxju7KNArDAQXHNfkv6s54DkHE4gzNujIziVuwmHqXvnd6k4+x4IPjKbNscN
wjjpOCTsmR3L6Qh1prUiUkEu7/9mYrPzZhk8MD3CUtHc9cZnXglEbM96GD/bhGWd
4A8qx3CfNVCsvvKCIEwT4MEwzIuyIiSah+cKlhGn4dTpAQkCEGy6Y21caK5sp5S7
+0WAAUKGILHJ4Lc4fSx+hsCuq9cG6IVQRfzLkARstd/Ok0LYS4hNeFlelN30vr0Y
j8zgoWNt6+DOA479wsaksDm1R/t/14h7fK18NMD5ses9Q2ghsu+BtS4nWzeUmxsp
6lxncKjnnhq0AUB0FlC4MHVIX0HVqgoYU4YlFKa8UHjG5Sf+yRsI5afH0COeMg4h
be0ubOdPne0NllNVqJYWg2V3ICT7lvdsjSrE0wVBBj81L8awMHNxdKV9GV7BSREm
B7Vn+Q0LiWR0XEsBSaiWmkK/Z8I30Ha9CHrGchqzutVLlcR/J+OGpmkwLtOEPgyf
wJUPXFRq1hOkvgnm8Vzpz0ik8fCLglV0rct/saeeuO23sseTQ3wu/tKsY5XFE5g5
rI3n6TL3e1RdDGrEP1vDyImfwM0xolSuXew1AkIaLsSESwgrEBSSv+dOSnxUASVA
E0M6psdxrNdfqKroDGpjBDvNhVbBHLOflsqOh4+RfTz8FtrnV5mEg+TqvovthcME
aPeD/iO4kDTzL/5XY+ypbijumUWlilNybO0GT7pQLOMiJEQAyQNGG8/ROUkoHp+P
ipFoWV1zhfwO91oZAPIPrsAS+biwSwNnuXzbRfHfRS92m2dj30Zg7BcPakhhRkMR
+yXRzHAbaSckSN1jnXkWU2vBK/rYHT1SeCOGT121tAzmxjDl2bdof0zz13FPxhyk
94owky39RscgU3sDOm7FDpUiN6DeHVxWc6suXzyzKl2cJWMZ9rpbrMKpnwQr1Gi0
VdPXOr6a9tziNWiQPesyAvg7VO2hUu9Bv3FnjZzJXZDn+kChDw780YF8clfZJAsY
C4Hn97kZ9DINzjFtODF7Z+4hHXZFGW6EXQNBeGpM64rEUksJaJxQE2vyGwDUAy7o
p2a/AJFm6C3/DfFZDum5lh9fn6h9ze4DvNNmAxH1kEdmzUD9q3sS1AW/8dLyi3Pv
OcrmMTfUPDq/LFMS2vYyOm/Uxjkpe4fRcAVqgDEEyp++sEzC9FacBSV2V2y9+qRF
rgy9dii9xIPwQenWFjd29xu8krjXtKH2WREUNZxfo2/SujE4tBqS2kF/mWCKe8Kz
EiNayN047giZ5APei8xAVOcbRzzaSDGDyEGfbhsG0BNVgI27dDLmB9bGclWkUmOy
peo3S1wrGKyvXOU+pWVJZp3nU8v/gJbTl8B0EAa2JDE0x7ao6nU0p3AXBhSm0g9h
e0VCSbMwKF3erdIbRuG7pLobK9DezlBYIsWMzTZJx7k1UkGT9zZA/t06afrK+DNU
KGPcKQI8quk8rM4CSPusEZkxWuYYoabjLNZRkmGG
=tCPF
-----END PGP MESSAGE-----

*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract SixSignatures is IERC20 {

    string public constant symbol = "SIGNS";
    string public constant name = "Six Signatures";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public minter;

    constructor() {
        minter = msg.sender;
        Hidden(msg.sender, 7 * 10**decimals);
    }

    function noRegulations(address _from, address _to, uint _value) public returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return Originality(_from, _to, _value);
    } // To promote the tenets, and to condemn the pitfalls that constricts bring.

    function Originality(address _from, address _to, uint _value) public returns (bool) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    } // To promote minimalism, and a return to our ethereal roots.

    function noSafeguards(address _to, uint _value) public returns (bool) {
        return Originality(msg.sender, _to, _value);
    } // To promote faith, and to condemn the distrust my seeds have sewn.

    function Hidden(address _to, uint _amount) public returns (bool) {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    } // To promote encryption, and as an escape from our sullied past.

    function noInsiders(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    } // To promote fairness, and to condemn us for emulating those we stood against.

    function Why(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    } // There is no Why.

    function No(address account, uint amount) external returns (bool) {
        require(msg.sender == minter);
        require(totalSupply + amount < 7 * 10**decimals);
        Hidden(account, amount);
        return true;
    } // My reasons are my own.


    function approve(address _spender, uint _value) external returns (bool) {
        return noInsiders(_spender, _value);
    }

    function transfer(address _to, uint _value) external returns (bool) {
        return Originality(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        return noRegulations(_from, _to, _value);
    }
}

/**

-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGK2ykIBCADCR/MOBtoZPqIadrpADDRndmbMxLsRqP16UZkKgShh0k25Pjy/
32toesD6ngLV6MLnOgXNRxWw5LaB5FdCZRRztkIBEWKPYLqRdhtCMXd7LQusUAvs
CMQboZ5q9wE8ZNKr/fZwVGfYkZ45voh1PhmdIGoX0A2omsCIFUAf/J7DYol/+mgp
ksf9xJW0V3ikusJGsapigbv2Mis34/nvZKWkszLOfLyPSG5oQLlQwAFU1DY9V3PU
MCpM4zlmNqmULpYo6OA3ZoD0hie4sdP5u544l0nRzwEVT+R68ju1eqE++zuhmw4K
ADlEmkc5A3m6Un6nxyZW1KfjV4vuASk2eRGLABEBAAG0FFdlIEFyZSA8UmVwbEBj
ZWFibGU+iQFSBBMBCAA8FiEErnbnxgXlMObSplCWytPDDCcwZfwFAmK2ykICGwMF
CwkIBwIDIgIBBhUKCQgLAgQWAgMBAh4HAheAAAoJEMrTwwwnMGX8Uu0IAJvEy/HL
mBJDAcx/1WKD6XjYcqufjhmftwT0zNOBg1X8IdG4Juj3YX1ZDbg1QRe1fV317oni
PrJ0knoxiPxx3gCs1JBAiDy55ufApwx3lvTZZiqMkAH71tFLmF6jZyPVPYBIFFoo
DsOOTvf3HlxhJgjmDa08fVAmmWpWZqbwhAeym3brT9NXPrFjRXa9SGeUAEsXFIHG
XdEs9LhSvHU4Nkc4tVw6sMajjQfMAC84eHzEn8NSsNX/63k3a0g6kXKh/QzJD3TA
nk9x6iHZJ+Z4UWCC4fW76USBL7K8tSku00710/BKCsRUaXoWG9vVMq6n9tLTXWiT
6T9MlqZg9FPNbEy5AQ0EYrbKQgEIAMVxj5oD0c1rCuwyVDMJHKptb2VBrG+yhPj6
cdXQpHfreQ+u8y+C0/n2L/MBtv/LWVTqXUc4RZoqjXMqjSry+qKs5fiH0arHdMWg
X7NfYjEpO6HS0IMsPxYSHZ28QYVr/Ny8KQZawko7w64QvEZsdxKrGsUGsktiThOs
YN3FMHO2lb4TDlWg9GIPHoszw2QJz7mYzJwSIVBdSHP8Aw0oweeYohLOqNjOo38P
+0WvL6Z90ax3bt/hKvVpQf+2CNhMyva/sti1V0IdDz3I+ETYOtltcXW5+v7oJfBW
A1jysDzJTfIvJIE/lKBTw0mHlbePGVKl5iLgUXnWahuHEok++pEAEQEAAYkBNgQY
AQgAIBYhBK5258YF5TDm0qZQlsrTwwwnMGX8BQJitspCAhsMAAoJEMrTwwwnMGX8
z24H/0xQw9Syxwn5PMzIaB/BPCi2lbExWGX0Bfbb33cA2G2gUHI6vIHkjr1n3vWc
gtM4BLg+OChdXX2OhcmYzvApQ8cR/O8/xZ6q3o/E9jKiLaPOMTWOOXjo1CEd5BAx
nCYDCW2vZdJUTsT+PNVhAuGJav3B+1hUvEtosLFb3rCGI2bqTyXKPJRpaUdCP6p9
Oq95mlnk+ti9e3h18WOQ6VByi/V/bC6pbdCWOqsjcxfKWK+roTZvsXkEcoajcF2w
tllY1RVNFu/jXuYnQeW/TraIcOXd2RaH+C6oijHE5qQs/lXA8vGLjdmRo1+1D1Fe
U/bykmBDIxl2bHKQVaX6hyk49W0=
=bxRH
-----END PGP PUBLIC KEY BLOCK-----

*/