/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.8.0;

interface spotLike {
    function poke(bytes32 ilk) external;
}

interface dogLike {
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id);
}

interface peepLike {
    function poke() external;
}

struct jugILK {
    uint256 duty;  // Collateral-specific, per-second stability fee contribution [ray]
    uint256  rho;  // Time of last drip [unix epoch time]
}

abstract contract JugLike {
    function drip(bytes32 ilk) virtual external returns (uint);

    mapping (bytes32 => jugILK) public ilks;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

interface DaiJoinLike_3 {
    function dai() external view returns (TokenLike_3);
    function vat() external view returns (address);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

abstract contract vatContract {
    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (address => uint256)                   public dai;
    function hope(address) external virtual;
}

interface TokenLike_3 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

contract kicker {
    dogLike public dog = dogLike(0x135954d155898D42C90D2a57824C690e0c7BEf1B);
    spotLike public spot = spotLike(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    vatContract public vat = vatContract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    IUniswapV2Pair public dai2eth = IUniswapV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    DaiJoinLike_3 public daiJoin = DaiJoinLike_3(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    TokenLike_3 public dai;
    JugLike public jug = JugLike(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address public owner;

    constructor() {
        owner = msg.sender;
        dai = daiJoin.dai();
        vat.hope(address(daiJoin));
    }

    function setDog(address _dog) external {
        require(msg.sender == owner, "only owner");
        dog = dogLike(_dog);
    }

    function setSpot(address _spot) external {
        require(msg.sender == owner, "only owner");
        spot = spotLike(_spot);
    }

    function setVat(vatContract _new) external {
        require(msg.sender == owner, "only owner");
        vat = _new;
    }

    function setDai2Eth(IUniswapV2Pair _new) external {
        require(msg.sender == owner, "only owner");
        dai2eth = _new;
    }

    function setDaiJoin(DaiJoinLike_3 _new) external {
        require(msg.sender == owner, "only owner");
        daiJoin = _new;
        vat.hope(address(daiJoin));
    }

    function setWEth(IWETH _new) external {
        require(msg.sender == owner, "only owner");
        weth = _new;
    }

    function barks(bytes32[] calldata ilk, address[][3][] calldata usrs, address[] calldata peeps, bool bribe) external {
        dogLike _dog = dog;
        spotLike _spot = spot;
        address kepr = address(this);
        uint256 rightNow = block.timestamp;
        for(uint256 i = 0; i < ilk.length; i ++) {
            bytes32 _ilk = ilk[i];
            (, uint256 rho) = jug.ilks(_ilk);
            if (rightNow > rho) {
                jug.drip(_ilk);
            }
            address[][3] calldata  _usrs = usrs[i];
            //console.log("Test0");

            //(bool success, ) = address(test).call(abi.encodeWithSelector(Test.Test2.selector, _ilk));
            //console.log("success %s", success);

            if (_usrs[0].length > 0) {
                //console.log("bark0");
                for(uint256 j = 0; j < _usrs[0].length; j ++) {
                    //console.log("bark0 @%s", _usrs[0][j]);
                    //_dog.bark(_ilk, _usrs[0][j], kepr);

                    address(_dog).call(abi.encodeWithSelector(
                            dogLike.bark.selector,
                            _ilk, _usrs[0][j], kepr));
                }
            }
            if (_usrs[1].length > 0) {
                //console.log("bark1");
                _spot.poke(_ilk);
                for(uint256 j = 0; j < _usrs[1].length; j ++) {
                    address usr = _usrs[1][j];


                    _dog.bark(_ilk, usr, kepr);

                    address(_dog).call(abi.encodeWithSelector(
                            dogLike.bark.selector,
                            _ilk, _usrs[1][j], kepr));
                }
            }

            if (_usrs[2].length > 0) {
                //console.log("bark2");
                //peepLike(peeps[i]).poke();
                address(peeps[i]).call(abi.encodeWithSelector(peepLike.poke.selector));

                _spot.poke(_ilk);

                for(uint256 j = 0; j < _usrs[2].length; j ++) {
                    //console.log("bark2 @%s", _usrs[2][j]);
                    address(_dog).call(abi.encodeWithSelector(
                            dogLike.bark.selector,
                            _ilk, _usrs[2][j], kepr));
                    //_dog.bark(_ilk, _usrs[2][j], kepr);
                }
            }

        }

        if (bribe) {
            sellForEthAndBride();
        }
    }

    function sellForEthAndBride() internal {
    unchecked {
        uint256 amount = vat.dai(address(this));
        amount = amount / (10 ** 27);
        daiJoin.exit(address(this), amount);

        //now we get all dai
        //swap half to bribe
        amount = amount / 2;
        (uint256 daiAmount, uint256 ethAmount, ) = dai2eth.getReserves();
        uint256 getBack = amount * 997 * ethAmount / (1000 * daiAmount + 997 * amount);
        safeTransfer(address(dai), address(dai2eth), amount);
        dai2eth.swap(0, getBack, address(this), "");
        weth.withdraw(getBack);
        block.coinbase.transfer(getBack);
    }
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        bool success;

        assembly {
        // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

        // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
            freeMemoryPointer,
            0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success :=
            and(
            // Set success to whether the call reverted, if not we check it either
            // returned exactly 1 (can't just be non-zero data), or had no return data.
            or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
            // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // Counterintuitively, this call must be positioned second to the or() call in the
            // surrounding and() call or else returndatasize() will be zero during the computation.
            call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }
        require(success, "T");
    }

    receive() external payable{}

    function withdrawlTokens(address[] calldata tokens) external {
        uint256 l = tokens.length;
        for(uint256 i = 0; i < l; i ++) {
            uint256 amount = TokenLike_3(tokens[i]).balanceOf(address(this));
            //TokenLike_3(tokens[i]).transfer(owner, amount);
            safeTransfer(tokens[i], owner, amount);
        }
    }

    function rpow(uint x, uint n, uint b) external pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := b} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := b } default { z := x }
                let half := div(b, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, b)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, b)
                    }
                }
            }
        }
    }

    function withdrawlETH() external {
        payable(owner).transfer(address(this).balance);
    }
}