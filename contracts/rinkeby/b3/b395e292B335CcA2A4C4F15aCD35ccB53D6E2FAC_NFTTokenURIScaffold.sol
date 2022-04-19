// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMetadata} from './SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {DateTime} from './DateTime.sol';
import './Base64.sol';
import {NFTSVG} from './NFTSVG.sol';

library NFTTokenURIScaffold {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    function tokenURI(
        uint256 id,
        IPair pair,
        IPair.Due memory due,
        uint256 maturity
    ) public view returns (string memory) {
        string memory uri = constructTokenSVG(
            address(pair.asset()),
            address(pair.collateral()),
            id.toString(),
            weiToPrecisionString(due.debt, pair.asset().safeDecimals()),
            weiToPrecisionString(due.collateral, pair.collateral().safeDecimals()),
            getReadableDateString(maturity),
            maturity
        );

        string memory description = string(
            abi.encodePacked(
                'This collateralized debt position represents a debt of ',
                weiToPrecisionString(due.debt, pair.asset().safeDecimals()),
                ' ',
                pair.asset().safeSymbol(),
                ' borrowed against a collateral of ',
                weiToPrecisionString(due.collateral, pair.collateral().safeDecimals()),
                ' ',
                pair.collateral().safeSymbol(),
                '. This position will expire on ',
                maturity.toString(),
                ' unix epoch time.\\nThe owner of this NFT has the option to pay the debt before maturity time to claim the locked collateral. In case the owner choose to default on the debt payment, the collateral will be forfeited'
            )
        );
        description = string(
            abi.encodePacked(
                description,
                '\\n\\nAsset Address: ',
                addressToString(address(pair.asset())),
                '\\nCollateral Address: ',
                addressToString(address(pair.collateral())),
                '\\nDebt Required: ',
                weiToPrecisionLongString(due.debt, pair.asset().safeDecimals()),
                ' ',
                IERC20(pair.asset()).safeSymbol(),
                '\\nCollateral Locked: ',
                weiToPrecisionLongString(due.collateral, pair.collateral().safeDecimals()),
                ' ',
                IERC20(pair.collateral()).safeSymbol()
            )
        );

        string memory name = 'Timeswap Collateralized Debt';

        return (constructTokenURI(name, description, uri));
    }

    function constructTokenURI(
        string memory name,
        string memory description,
        string memory imageSVG
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                Base64.encode(bytes(imageSVG)),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function constructTokenSVG(
        address asset,
        address collateral,
        string memory tokenId,
        string memory assetAmount,
        string memory collateralAmount,
        string memory maturityDate,
        uint256 maturityTimestamp
    ) internal view returns (string memory) {
        NFTSVG.SVGParams memory params = NFTSVG.SVGParams({
            tokenId: tokenId,
            svgTitle: string(
                abi.encodePacked(
                    parseSymbol(IERC20(asset).safeSymbol()),
                    '/',
                    parseSymbol(IERC20(collateral).safeSymbol())
                )
            ),
            assetInfo: string(abi.encodePacked(parseSymbol(IERC20(asset).safeSymbol()), ': ', addressToString(asset))),
            collateralInfo: string(
                abi.encodePacked(parseSymbol(IERC20(collateral).safeSymbol()), ': ', addressToString(collateral))
            ),
            debtRequired: string(abi.encodePacked(assetAmount, ' ', parseSymbol(IERC20(asset).safeSymbol()))),
            collateralLocked: string(
                abi.encodePacked(collateralAmount, ' ', parseSymbol(IERC20(collateral).safeSymbol()))
            ),
            maturityDate: maturityDate,
            isMatured: block.timestamp > maturityTimestamp,
            maturityTimestampString: maturityTimestamp.toString(),
            tokenColors: getSVGCData(asset, collateral)
        });

        return NFTSVG.constructSVG(params);
    }

    function weiToPrecisionLongString(uint256 weiAmt, uint256 decimal) public pure returns (string memory) {
        if (decimal == 0) {
            return string(abi.encodePacked(weiAmt.toString(), '.00'));
        }

        uint256 significantDigits = weiAmt / (10**decimal);
        uint256 precisionDigits = weiAmt % (10**(decimal));

        if (precisionDigits == 0) {
            return string(abi.encodePacked(significantDigits.toString(), '.00'));
        }

        string memory precisionDigitsString = toStringTrimmed(precisionDigits);
        uint256 lengthDiff = decimal - bytes(precisionDigits.toString()).length;
        for (uint256 i; i < lengthDiff; ) {
            precisionDigitsString = string(abi.encodePacked('0', precisionDigitsString));
            unchecked {
                ++i;
            }
        }

        return string(abi.encodePacked(significantDigits.toString(), '.', precisionDigitsString));
    }

    function weiToPrecisionString(uint256 weiAmt, uint256 decimal) public pure returns (string memory) {
        if (decimal == 0) {
            return string(abi.encodePacked(weiAmt.toString(), '.00'));
        }

        uint256 significantDigits = weiAmt / (10**decimal);
        if (significantDigits > 1e9) {
            string memory weiAmtString = weiAmt.toString();
            uint256 len = bytes(weiAmtString).length - 9;
            weiAmt = weiAmt / (10**len);
            return string(abi.encodePacked(weiAmt.toString(), '...'));
        }
        uint256 precisionDigits = weiAmt % (10**(decimal));
        precisionDigits = precisionDigits / (10**(decimal - 4));

        if (precisionDigits == 0) {
            return string(abi.encodePacked(significantDigits.toString(), '.00'));
        }

        string memory precisionDigitsString = toStringTrimmed(precisionDigits);
        uint256 lengthDiff = 4 - bytes(precisionDigits.toString()).length;
        for (uint256 i; i < lengthDiff; ) {
            precisionDigitsString = string(abi.encodePacked('0', precisionDigitsString));
            unchecked {
                ++i;
            }
        }

        return string(abi.encodePacked(significantDigits.toString(), '.', precisionDigitsString));
    }

    function toStringTrimmed(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        uint256 flag;
        while (temp != 0) {
            if (flag == 0 && temp % 10 == 0) {
                temp /= 10;
                continue;
            } else if (flag == 0 && temp % 10 != 0) {
                flag++;
                digits++;
            } else {
                digits++;
            }

            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        flag = 0;
        while (value != 0) {
            if (flag == 0 && value % 10 == 0) {
                value /= 10;
                continue;
            } else if (flag == 0 && value % 10 != 0) {
                flag++;
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            } else {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            }

            value /= 10;
        }
        return string(buffer);
    }

    function addressToString(address _addr) public pure returns (string memory) {
        bytes memory data = abi.encodePacked(_addr);
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i; i < data.length; ) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
            unchecked {
                ++i;
            }
        }
        return string(str);
    }

    function getSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) public pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i; i <= end - begin; ) {
            a[i] = bytes(text)[i + begin - 1];
            unchecked {
                ++i;
            }
        }
        return string(a);
    }

    function parseSymbol(string memory symbol) public pure returns (string memory) {
        if (bytes(symbol).length > 5) {
            return getSlice(1, 5, symbol);
        }
        return symbol;
    }

    function getMonthString(uint256 _month) public pure returns (string memory) {
        string[12] memory months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[_month];
    }

    function getReadableDateString(uint256 timestamp) public pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime
            .timestampToDateTime(timestamp);

        string memory result = string(
            abi.encodePacked(
                day.toString(),
                ' ',
                getMonthString(month - 1),
                ' ',
                year.toString(),
                ', ',
                padWithZero(hour),
                ':',
                padWithZero(minute),
                ':',
                padWithZero(second),
                ' UTC'
            )
        );
        return result;
    }

    function padWithZero(uint256 value) public pure returns (string memory) {
        if (value < 10) {
            return string(abi.encodePacked('0', value.toString()));
        }
        return value.toString();
    }

    function getLightColor(address token) public pure returns (string memory) {
        string[15] memory lightColors = [
            'F7BAF7',
            'F7C8BA',
            'FAE2BE',
            'BAE1F7',
            'EBF7BA',
            'CEF7BA',
            'CED2EF',
            'CABAF7',
            'BAF7E5',
            'BACFF7',
            'F7BAE3',
            'F7E9BA',
            'E0BAF7',
            'F7BACF',
            'FFFFFF'
        ];
        uint160 tokenValue = uint160(token) % 15;
        return (lightColors[tokenValue]);
    }

    function getDarkColor(address token) public pure returns (string memory) {
        string[15] memory darkColors = [
            'DF51EC',
            'EC7651',
            'ECAE51',
            '51B4EC',
            'A4C327',
            '59C327',
            '5160EC',
            '7951EC',
            '27C394',
            '5185EC',
            'EC51B8',
            'F4CB3A',
            'B151EC',
            'EC5184',
            'C5C0C2'
        ];
        uint160 tokenValue = uint160(token) % 15;
        return (darkColors[tokenValue]);
    }

    function getSVGCData(address asset, address collateral) public pure returns (string memory) {
        string memory token0LightColor = string(abi.encodePacked('.C{fill:#', getLightColor(asset), '}'));
        string memory token0DarkColor = string(abi.encodePacked('.D{fill:#', getDarkColor(asset), '}'));
        string memory token1LightColor = string(abi.encodePacked('.E{fill:#', getLightColor(collateral), '}'));
        string memory token1DarkColor = string(abi.encodePacked('.F{fill:#', getDarkColor(collateral), '}'));

        return string(abi.encodePacked(token0LightColor, token0DarkColor, token1LightColor, token1DarkColor));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IFactory} from './IFactory.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPair {
    /* ===== STRUCT ===== */

    struct Tokens {
        uint128 asset;
        uint128 collateral;
    }

    struct Claims {
        uint112 bondPrincipal;
        uint112 bondInterest;
        uint112 insurancePrincipal;
        uint112 insuranceInterest;
    }

    struct Due {
        uint112 debt;
        uint112 collateral;
        uint32 startBlock;
    }

    struct State {
        Tokens reserves;
        uint256 feeStored;
        uint256 totalLiquidity;
        Claims totalClaims;
        uint120 totalDebtCreated;
        uint112 x;
        uint112 y;
        uint112 z;
    }

    struct Pool {
        State state;
        mapping(address => uint256) liquidities;
        mapping(address => Claims) claims;
        mapping(address => Due[]) dues;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param liquidityTo The address of the receiver of liquidity balance.
    /// @param dueTo The addres of the receiver of collateralized debt balance.
    /// @param xIncrease The increase in the X state.
    /// @param yIncrease The increase in the Y state.
    /// @param zIncrease The increase in the Z state.
    /// @param data The data for callback.
    struct MintParam {
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 xIncrease;
        uint112 yIncrease;
        uint112 zIncrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param liquidityIn The amount of liquidity balance burnt by the msg.sender.
    struct BurnParam {
        uint256 maturity;
        address assetTo;
        address collateralTo;
        uint256 liquidityIn;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param bondTo The address of the receiver of bond balance.
    /// @param insuranceTo The addres of the receiver of insurance balance.
    /// @param xIncrease The increase in x state and the amount of asset ERC20 sent.
    /// @param yDecrease The decrease in y state.
    /// @param zDecrease The decrease in z state.
    /// @param data The data for callback.
    struct LendParam {
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 xIncrease;
        uint112 yDecrease;
        uint112 zDecrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param claimsIn The amount of bond balance and insurance balance burnt by the msg.sender.
    struct WithdrawParam {
        uint256 maturity;
        address assetTo;
        address collateralTo;
        Claims claimsIn;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param dueTo The address of the receiver of collateralized debt.
    /// @param xDecrease The decrease in x state and amount of asset ERC20 received by assetTo.
    /// @param yIncrease The increase in y state.
    /// @param zIncrease The increase in z state.
    /// @param data The data for callback.
    struct BorrowParam {
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 xDecrease;
        uint112 yIncrease;
        uint112 zIncrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param to The address of the receiver of collateral ERC20.
    /// @param owner The addres of the owner of collateralized debt.
    /// @param ids The array indexes of collateralized debts.
    /// @param assetsIn The amount of asset ERC20 paid per collateralized debts.
    /// @param collateralsOut The amount of collateral ERC20 withdrawn per collaterlaized debts.
    /// @param data The data for callback.
    struct PayParam {
        uint256 maturity;
        address to;
        address owner;
        uint256[] ids;
        uint112[] assetsIn;
        uint112[] collateralsOut;
        bytes data;
    }

    /* ===== EVENT ===== */

    /// @dev Emits when the state gets updated.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param x The new x state of the pool.
    /// @param y The new y state of the pool.
    /// @param z The new z state of the pool.
    event Sync(uint256 indexed maturity, uint112 x, uint112 y, uint112 z);

    /// @dev Emits when mint function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param liquidityTo The address of the receiver of liquidity balance.
    /// @param dueTo The address of the receiver of collateralized debt balance.
    /// @param assetIn The increase in the X state.
    /// @param liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @param id The array index of the collateralized debt received by dueTo.
    /// @param dueOut The collateralized debt received by dueTo.
    /// @param feeIn The amount of fee asset ERC20 deposited.
    event Mint(
        uint256 maturity,
        address indexed sender,
        address indexed liquidityTo,
        address indexed dueTo,
        uint256 assetIn,
        uint256 liquidityOut,
        uint256 id,
        Due dueOut,
        uint256 feeIn
    );

    /// @dev Emits when burn function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param liquidityIn The amount of liquidity balance burnt by the sender.
    /// @param assetOut The amount of asset ERC20 received.
    /// @param collateralOut The amount of collateral ERC20 received.
    /// @param feeOut The amount of fee asset ERC20 received.
    event Burn(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed collateralTo,
        uint256 liquidityIn,
        uint256 assetOut,
        uint128 collateralOut,
        uint256 feeOut
    );

    /// @dev Emits when lend function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param bondTo The address of the receiver of bond balance.
    /// @param insuranceTo The addres of the receiver of insurance balance.
    /// @param assetIn The increase in X state.
    /// @param claimsOut The amount of bond balance and insurance balance received.
    /// @param feeIn The amount of fee paid by lender.
    /// @param protocolFeeIn The amount of protocol fee paid by lender.
    event Lend(
        uint256 maturity,
        address indexed sender,
        address indexed bondTo,
        address indexed insuranceTo,
        uint256 assetIn,
        Claims claimsOut,
        uint256 feeIn,
        uint256 protocolFeeIn
    );

    /// @dev Emits when withdraw function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The address of the receiver of collateral ERC20.
    /// @param claimsIn The amount of bond balance and insurance balance burnt by the sender.
    /// @param tokensOut The amount of asset ERC20 and collateral ERC20 received.
    event Withdraw(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed collateralTo,
        Claims claimsIn,
        Tokens tokensOut
    );

    /// @dev Emits when borrow function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param dueTo The address of the receiver of collateralized debt.
    /// @param assetOut The amount of asset ERC20 received by assetTo.
    /// @param id The array index of the collateralized debt received by dueTo.
    /// @param dueOut The collateralized debt received by dueTo.
    /// @param feeIn The amount of fee paid by lender.
    /// @param protocolFeeIn The amount of protocol fee paid by lender.
    event Borrow(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed dueTo,
        uint256 assetOut,
        uint256 id,
        Due dueOut,
        uint256 feeIn,
        uint256 protocolFeeIn
    );

    /// @dev Emits when pay function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param to The address of the receiver of collateral ERC20.
    /// @param owner The address of the owner of collateralized debt.
    /// @param ids The array indexes of collateralized debts.
    /// @param assetsIn The amount of asset ERC20 paid per collateralized debts.
    /// @param collateralsOut The amount of collateral ERC20 withdrawn per collaterelized debts.
    /// @param assetIn The total amount of asset ERC20 paid.
    /// @param collateralOut The total amount of collateral ERC20 received.
    event Pay(
        uint256 maturity,
        address indexed sender,
        address indexed to,
        address indexed owner,
        uint256[] ids,
        uint112[] assetsIn,
        uint112[] collateralsOut,
        uint128 assetIn,
        uint128 collateralOut
    );

    /// @dev Emits when collectProtocolFee function is called
    /// @param sender The address of the caller.
    /// @param to The address of the receiver of asset ERC20.
    /// @param protocolFeeOut The amount of protocol fee asset ERC20 received.
    event CollectProtocolFee(
        address indexed sender,
        address indexed to,
        uint256 protocolFeeOut
    );

    /* ===== VIEW ===== */

    /// @dev Return the address of the factory contract that deployed this contract.
    /// @return The address of the factory contract.
    function factory() external view returns (IFactory);

    /// @dev Return the address of the ERC20 being lent and borrowed.
    /// @return The address of the asset ERC20.
    function asset() external view returns (IERC20);

    /// @dev Return the address of the ERC20 as collateral.
    /// @return The address of the collateral ERC20.
    function collateral() external view returns (IERC20);

    //// @dev Return the fee per second earned by liquidity providers.
    /// @dev Must be downcasted to uint16.
    //// @return The transaction fee following the UQ0.40 format.
    function fee() external view returns (uint256);

    /// @dev Return the protocol fee per second earned by the owner.
    /// @dev Must be downcasted to uint16.
    /// @return The protocol fee per second following the UQ0.40 format.
    function protocolFee() external view returns (uint256);

    /// @dev Return the fee stored of the Pool given maturity.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The fee in asset ERC20 stored in the Pool.
    function feeStored(uint256 maturity) external view returns (uint256);

    /// @dev Return the protocol fee stored.
    /// @return The protocol fee in asset ERC20 stored.
    function protocolFeeStored() external view returns (uint256);

    /// @dev Returns the Constant Product state of a Pool.
    /// @dev The Y state follows the UQ80.32 format.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return x The x state.
    /// @return y The y state.
    /// @return z The z state.
    function constantProduct(uint256 maturity)
        external
        view
        returns (
            uint112 x,
            uint112 y,
            uint112 z
        );

    /// @dev Returns the asset ERC20 and collateral ERC20 balances of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The asset ERC20 and collateral ERC20 locked.
    function totalReserves(uint256 maturity) external view returns (Tokens memory);

    /// @dev Returns the total liquidity supply of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total liquidity supply.
    function totalLiquidity(uint256 maturity) external view returns (uint256);

    /// @dev Returns the liquidity balance of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @return The liquidity balance.
    function liquidityOf(uint256 maturity, address owner) external view returns (uint256);

    /// @dev Returns the total claims of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total claims.
    function totalClaims(uint256 maturity) external view returns (Claims memory);

    /// @dev Returms the claims of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @return The claims balance.
    function claimsOf(uint256 maturity, address owner) external view returns (Claims memory);

    /// @dev Returns the total debt created.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total asset ERC20 debt created.
    function totalDebtCreated(uint256 maturity) external view returns (uint120);

    /// @dev Returns the number of dues owned by owner.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    function totalDuesOf(uint256 maturity, address owner) external view returns (uint256);

    /// @dev Returns a collateralized debt of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @param id The index of the collateralized debt
    /// @return The collateralized debt balance.
    function dueOf(uint256 maturity, address owner, uint256 id) external view returns (Due memory);

    /* ===== UPDATE ===== */

    /// @dev Add liquidity into a Pool by a liquidity provider.
    /// @dev Liquidity providers can be thought as making both lending and borrowing positions.
    /// @dev Must be called by a contract implementing the ITimeswapMintCallback interface.
    /// @param param The mint parameter found in the MintParam struct.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function mint(MintParam calldata param)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            Due memory dueOut
        );

    /// @dev Remove liquidity from a Pool by a liquidity provider.
    /// @dev Can only be called after the maturity of the Pool.
    /// @param param The burn parameter found in the BurnParam struct.
    /// @return assetOut The amount of asset ERC20 received.
    /// @return collateralOut The amount of collateral ERC20 received.
    function burn(BurnParam calldata param) 
        external 
        returns (
            uint256 assetOut,
            uint128 collateralOut 
        );

    /// @dev Lend asset ERC20 into the Pool.
    /// @dev Must be called by a contract implementing the ITimeswapLendCallback interface.
    /// @param param The lend parameter found in the LendParam struct.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond balance and insurance balance received.
    function lend(LendParam calldata param) 
        external 
        returns (
            uint256 assetIn,
            Claims memory claimsOut
        );

    /// @dev Withdraw asset ERC20 and/or collateral ERC20 for lenders.
    /// @dev Can only be called after the maturity of the Pool.
    /// @param param The withdraw parameter found in the WithdrawParam struct.
    /// @return tokensOut The amount of asset ERC20 and collateral ERC20 received.
    function withdraw(WithdrawParam calldata param)
        external 
        returns (
            Tokens memory tokensOut
        );

    /// @dev Borrow asset ERC20 from the Pool.
    /// @dev Must be called by a contract implementing the ITimeswapBorrowCallback interface.
    /// @param param The borrow parameter found in the BorrowParam struct.
    /// @return assetOut The amount of asset ERC20 received.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function borrow(BorrowParam calldata param)
        external 
        returns (
            uint256 assetOut,
            uint256 id, 
            Due memory dueOut
        );

    /// @dev Pay asset ERC20 into the Pool to repay debt for borrowers.
    /// @dev If there are asset paid, must be called by a contract implementing the ITimeswapPayCallback interface.
    /// @param param The pay parameter found in the PayParam struct.
    /// @return assetIn The total amount of asset ERC20 paid.
    /// @return collateralOut The total amount of collateral ERC20 received.
    function pay(PayParam calldata param)
        external 
        returns (
            uint128 assetIn, 
            uint128 collateralOut
        );

    /// @dev Collect the stored protocol fee.
    /// @dev Can only be called by the owner.
    /// @param to The receiver of the protocol fee.
    /// @return protocolFeeOut The total amount of protocol fee asset ERC20 received.
    function collectProtocolFee(address to) external returns (uint256 protocolFeeOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

library SafeMetadata {
function isSafeString(string memory str) public pure returns (bool) {
    bytes memory b = bytes(str);

    for(uint i; i<b.length; i++) {
        bytes1 char = b[i];
        if( !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) && !(char == 0x20) // ." "
        )
        return false;
    }
    return true;
}
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.name.selector)
        );
        return success ? returnDataToString(data) : 'Token';
    }

    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool _success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.symbol.selector)
        );
        string memory tokenSymbol = _success ? returnDataToString(data) : 'TKN';

        bool success = isSafeString(tokenSymbol);
        return success ? tokenSymbol: 'TKN';
    }


    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function returnDataToString(bytes memory data) private pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i;
            while (i < 32 && data[i] != 0) {
                unchecked {
                    ++i;
                }
            }
            bytes memory bytesArray = new bytes(i);
            uint256 length = bytesArray.length;
            for (i = 0; i < length; ) {
                bytesArray[i] = data[i];
                unchecked {
                    ++i;
                }
            }
            return string(bytesArray);
        } else {
            return '???';
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_HOUR = 3600;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month != 0 && month <= 12) {
            if (day != 0 && day <= _getDaysInMonth(year, month)) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library NFTSVG {
    struct SVGParams {
        string tokenId;
        string svgTitle;
        string assetInfo;
        string collateralInfo;
        string debtRequired;
        string collateralLocked;
        string maturityDate;
        string maturityTimestampString;
        string tokenColors;
        bool isMatured;
    }

    function constructSVG(SVGParams memory params) public pure returns (string memory) {
        string memory colorScheme = params.isMatured
            ? '.G{stop-color:#3C3C3C}.H{fill:#959595}.I{stop-color:#000000}.J{stop-color:#FFFFFF}'
            : '.G{stop-color:#20087E}.H{fill:#5457D7}.I{stop-color:#61F6FF}.J{stop-color:#3C43FF}';

        string memory svg = string(
            abi.encodePacked(
                '<svg width="290" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style type="text/css" ><![CDATA[.B{fill-rule:evenodd}',
                params.tokenColors,
                colorScheme,
                ']]></style><g clip-path="url(#mainclip)"><rect width="290" height="500" fill="url(\'#background\')"/><rect y="409" width="290" height="90" fill="#141330" fill-opacity="0.4"/><rect y="408" width="290" height="2" fill="url(#divider)"/></g><text y="70px" x="145" fill="white" font-family="arial" font-weight="500" font-size="24px" text-anchor="middle">'
            )
        );

        svg = string(
            abi.encodePacked(
                svg,
                params.svgTitle,
                '</text><text y="95px" x="145" fill="white" font-family="arial" font-weight="400" font-size="12px" text-anchor="middle">',
                params.maturityDate,
                '</text>'
            )
        );

        if (!params.isMatured) {
            string memory maturityInfo = string(abi.encodePacked('MATURITY: ', params.maturityTimestampString));
            svg = string(
                abi.encodePacked(
                    svg,
                    '<text y="115px" x="145" fill="white" font-family="arial" font-weight="300" font-size="10px" text-anchor="middle" opacity="50%">',
                    maturityInfo,
                    '</text>'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<rect width="74" height="22" rx="13" y="110" x="107" text-anchor="middle" fill="#FFFFFF" /><text y="125px" x="145" fill="black" font-family="arial" font-weight="600" font-size="10px" letter-spacing="1" text-anchor="middle">MATURED</text>'
                )
            );
        }

        svg = string(
            abi.encodePacked(
                svg,
                '<text text-rendering="optimizeSpeed"><textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                params.assetInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                params.assetInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                params.collateralInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                params.collateralInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text><text y="435px" x="12" fill="white" font-family="arial" font-weight="400" font-size="13px" opacity="60%">ID:</text><text y="435px" x="278" fill="white" font-family="arial" font-weight="500" font-size="13px" text-anchor="end">'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                params.tokenId,
                '</text><text y="460px" x="12" fill="white" font-family="arial" font-weight="400" font-size="13px" opacity="60%">Debt required:</text><text y="460px" x="278" fill="white" font-family="arial" font-weight="500" font-size="13px" text-anchor="end">',
                params.debtRequired,
                '</text><text y="484px" x="12" fill="white" font-family="arial" font-weight="400" font-size="13px" opacity="60%">Collateral locked:</text><text y="484px" x="278" fill="white" font-family="arial" font-weight="500" font-size="13px" text-anchor="end">',
                params.collateralLocked,
                '</text><g filter="url(#filter0_f)"><path d="M253 319.5C253 346.838 204.871 369 145.5 369C86.1294 369 38 346.838 38 319.5C38 292.162 86.1294 270 145.5 270C204.871 270 253 292.162 253 319.5Z" class="H"/></g>'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                '<path d="M144.235 272.663h4.147v11.255h-4.147zm62.092 19.456l2.074 2.089-16.76 5.627-2.074-2.089zm-26.564-14.565l3.591 1.206-9.676 9.747-3.591-1.206zm37.046 34.903v2.412h-19.353v-2.412zm-33.454 36.11l-3.591 1.206-9.676-9.747 3.591-1.206zm25.046-15.448l-2.074 2.089-16.76-5.627 2.074-2.089zm-64.165 10.289h4.147v11.255h-4.147zm-43.258-15.916l2.074 2.089-16.76 5.627-2.074-2.089zm17.962 11.328l3.591 1.206-9.676 9.747-3.591-1.206zm-25.778-26.157v2.412H73.809v-2.412zm28.915-26.253l-3.591 1.206-9.676-9.747 3.591-1.206zm-20.434 10.881l-2.074 2.089-16.76-5.627 2.074-2.089z" fill="#6fa4d4"/><path d="M198.383 344.249C211.892 336.376 220 325.646 220 314s-8.108-22.376-21.617-30.249C184.898 275.893 166.204 271 145.5 271s-39.398 4.893-52.883 12.751C79.108 291.624 71 302.354 71 314s8.108 22.376 21.617 30.249C106.102 352.107 124.796 357 145.5 357s39.398-4.893 52.883-12.751zM145.5 358c41.698 0 75.5-19.699 75.5-44s-33.802-44-75.5-44S70 289.699 70 314s33.803 44 75.5 44zm56.402-10.206C216.307 339.026 225 327.049 225 314s-8.693-25.026-23.098-33.794C187.516 271.449 167.577 266 145.5 266s-42.016 5.449-56.402 14.206C74.694 288.974 66 300.951 66 314s8.694 25.026 23.098 33.794C103.484 356.551 123.423 362 145.5 362s42.016-5.449 56.402-14.206zM145.5 363c44.459 0 80.5-21.938 80.5-49s-36.041-49-80.5-49S65 286.938 65 314s36.041 49 80.5 49z" fill-rule="evenodd" fill="#6fa4d5"/><path d="M189.764 303.604c0 14.364-19.951 26.008-44.562 26.008-24.343 0-44.127-11.392-44.555-25.54v6.92.363c0 14.38 19.951 26.022 44.562 26.022s44.562-11.642 44.562-26.022v-.363-7.574h-.008l.001.186z" fill="#7fc2e2"/><path d="M145.202 326.408c21.834 0 39.533-10.256 39.533-22.906s-17.699-22.906-39.533-22.906-39.533 10.255-39.533 22.906 17.7 22.906 39.533 22.906z" fill="#020136"/><path d="M189.764 303.604c0 14.364-19.951 26.008-44.562 26.008s-44.562-11.644-44.562-26.008 19.951-26.008 44.562-26.008 44.562 11.644 44.562 26.008zm-5.029-.102c0 12.65-17.699 22.906-39.533 22.906s-39.533-10.255-39.533-22.906 17.699-22.906 39.533-22.906 39.533 10.256 39.533 22.906z" fill="#4f95b8" class="B"/><path d="M184.753 303.84v-5.406c0-18.859-10.806-36.185-28.114-45.047l-3.987-2.053a2.31 2.31 0 0 1-.975-.848 2.46 2.46 0 0 1-.39-1.259 2.47 2.47 0 0 1 .316-1.282c.216-.384.536-.699.924-.908l6.693-3.887c15.85-9.252 25.533-25.798 25.533-43.637V184h-78.996v15.095c0 18.065 9.925 34.782 26.098 43.959l6.772 3.846a2.34 2.34 0 0 1 .937.911c.223.39.334.839.321 1.293s-.15.894-.395 1.27-.588.671-.988.851l-4.105 2.053c-17.598 8.772-28.64 26.249-28.64 45.32v4.948c-.624 6.062 3.212 12.255 11.581 16.901 15.515 8.616 40.595 8.664 56.011.096 8.238-4.584 12.008-10.688 11.404-16.703h0z" fill="#fff" fill-opacity=".3"/><path d="M154.382 238.266c3.037-5.261 3.007-10.965-.062-12.737l2.734 1.579c3.069 1.772 3.098 7.476.061 12.737s-7.992 8.088-11.061 6.316l-2.734-1.579c3.069 1.772 8.025-1.055 11.062-6.315v-.001z" class="D"/><path d="M154.382 238.266c3.037-5.261 3.007-10.965-.062-12.737s-8.024 1.055-11.061 6.316-3.008 10.965.061 12.737 8.025-1.055 11.062-6.315v-.001zm-1.402-.809c2.27-3.932 2.252-8.2-.045-9.526s-6.004.792-8.274 4.724-2.247 8.192.051 9.519 5.998-.784 8.268-4.716v-.001z" class="B C"/><path d="M152.935 227.929c2.297 1.326 2.315 5.595.045 9.526s-5.971 6.042-8.268 4.716-2.321-5.587-.051-9.519 5.975-6.051 8.273-4.724l.001.001z" class="D"/><path d="M148.854 232.173l1.827-2.157c.303-.364.664-.269.607.154l-.349 2.545c-.021.163.023.302.121.349l1.488.806c.241.139.107.695-.237.951l-2.028 1.534a.91.91 0 0 0-.316.438l-.91 2.656c-.155.449-.597.692-.75.437l-.938-1.578c-.031-.052-.08-.09-.139-.107s-.121-.01-.174.019l-2.043.841c-.35.139-.475-.274-.238-.686l1.458-2.525a.81.81 0 0 0 .118-.492l-.345-2.136a.8.8 0 0 1 .142-.539.81.81 0 0 1 .457-.318l1.85.033a.56.56 0 0 0 .223-.071.57.57 0 0 0 .176-.155v.001z" class="C"/><path d="M166.548 230.55c4.318-4.272 5.796-9.782 3.303-12.302l2.221 2.245c2.492 2.519 1.014 8.029-3.304 12.301s-9.844 5.691-12.336 3.171l-2.221-2.245c2.492 2.52 8.018 1.102 12.337-3.17z" class="D"/><path d="M166.548 230.549c4.318-4.272 5.796-9.782 3.303-12.302s-8.017-1.101-12.336 3.171-5.797 9.782-3.304 12.301 8.018 1.102 12.337-3.17zm-1.139-1.151c3.228-3.193 4.338-7.314 2.472-9.2s-6-.821-9.227 2.371-4.33 7.308-2.464 9.194 5.993.827 9.22-2.366l-.001.001z" class="B C"/><path d="M167.881 220.199c1.866 1.886.755 6.008-2.472 9.2s-7.354 4.252-9.22 2.366-.763-6.002 2.464-9.194 7.36-4.258 9.227-2.371l.001-.001z" class="D"/><path d="M162.824 223.215l2.332-1.599c.388-.271.711-.084.545.308l-1.008 2.363c-.064.152-.057.298.024.369l1.222 1.17c.196.198-.08.699-.48.854l-2.361.944c-.172.067-.318.186-.421.339l-1.579 2.321c-.268.392-.758.51-.839.224l-.488-1.77c-.015-.059-.052-.109-.104-.141s-.115-.04-.174-.026l-2.193.271c-.375.042-.386-.39-.048-.725l2.072-2.05a.81.81 0 0 0 .244-.443l.231-2.151a.81.81 0 0 1 .28-.483c.148-.123.333-.188.524-.186l1.776.52c.078.013.158.01.234-.009a.56.56 0 0 0 .211-.103v.003z" class="C"/><path d="M131.352 236.907c4.692 3.858 10.325 4.762 12.576 2.024l-2.005 2.439c-2.251 2.738-7.883 1.832-12.575-2.025s-6.67-9.208-4.419-11.946l2.005-2.439c-2.251 2.738-.274 8.089 4.419 11.947h-.001z" class="D"/><path d="M131.352 236.907c4.692 3.858 10.325 4.762 12.576 2.024s.273-8.088-4.419-11.946-10.324-4.763-12.575-2.025-.274 8.089 4.419 11.947h-.001zm1.028-1.251c3.507 2.883 7.721 3.564 9.405 1.515s.202-6.052-3.305-8.935-7.714-3.558-9.399-1.508-.208 6.046 3.299 8.929v-.001z" class="B C"/><path d="M141.785 237.172c-1.685 2.049-5.898 1.368-9.405-1.515s-4.983-6.879-3.299-8.929 5.892-1.374 9.399 1.509 4.991 6.885 3.305 8.935z" class="D"/><path d="M138.267 232.451l1.829 2.156c.309.359.156.699-.251.574l-2.454-.76c-.157-.048-.302-.026-.364.062l-1.039 1.335c-.177.215-.703-.008-.899-.39l-1.181-2.252c-.084-.164-.217-.298-.381-.384l-2.471-1.333c-.417-.227-.585-.702-.309-.812l1.71-.667c.057-.021.103-.064.128-.12s.03-.117.009-.174l-.495-2.153c-.08-.368.349-.424.716-.122l2.252 1.851a.81.81 0 0 0 .466.197l2.164.009a.81.81 0 0 1 .509.228c.138.134.221.312.239.503l-.336 1.82a.59.59 0 0 0 .033.232c.026.074.069.142.124.2h.001z" class="C"/><path d="M119.071 225.508c3.876 4.677 9.235 6.633 11.964 4.372l-2.431 2.015c-2.729 2.261-8.087.305-11.963-4.373s-4.803-10.306-2.074-12.567l2.431-2.015c-2.729 2.261-1.802 7.89 2.073 12.568z" class="D"/><path d="M119.071 225.508c3.876 4.677 9.235 6.633 11.964 4.372s1.802-7.89-2.074-12.567-9.234-6.634-11.963-4.373-1.802 7.89 2.073 12.568zm1.247-1.033c2.897 3.496 6.905 4.964 8.947 3.271s1.346-5.904-1.551-9.4-6.9-4.956-8.942-3.263-1.351 5.896 1.546 9.392h0z" class="B C"/><path d="M129.265 227.745c-2.043 1.693-6.051.225-8.947-3.271s-3.589-7.699-1.546-9.392 6.045-.233 8.942 3.263 3.595 7.707 1.551 9.4h0z" class="D"/><path d="M126.705 222.444l1.387 2.463c.235.411.021.716-.355.516l-2.265-1.212c-.145-.077-.292-.083-.369-.008l-1.273 1.114c-.214.177-.689-.141-.809-.553l-.733-2.435a.9.9 0 0 0-.301-.449l-2.173-1.777c-.367-.302-.441-.8-.149-.856l1.806-.331c.06-.01.114-.043.15-.092s.05-.111.041-.171l-.078-2.208c-.009-.377.423-.35.726.016l1.86 2.245a.81.81 0 0 0 .42.282l2.123.419c.186.049.347.163.456.32s.158.349.139.539l-.674 1.723c-.02.077-.023.156-.012.234s.041.152.084.219l-.001.002z" class="C"/><path d="M140.196 225.21c5.607 2.338 11.261 1.576 12.624-1.695l-1.215 2.914c-1.364 3.271-7.017 4.031-12.624 1.694s-9.046-6.888-7.682-10.16l1.215-2.914c-1.364 3.271 2.075 7.823 7.682 10.161h0z" class="D"/><path d="M140.196 225.211c5.607 2.337 11.261 1.576 12.624-1.695s-2.075-7.822-7.682-10.16-11.26-1.577-12.624 1.694 2.075 7.823 7.682 10.161h0zm.623-1.494c4.19 1.747 8.421 1.182 9.442-1.266s-1.555-5.853-5.746-7.599-8.413-1.178-9.434 1.271 1.547 5.848 5.737 7.595l.001-.001z" class="B C"/><path d="M150.261 222.449c-1.021 2.449-5.252 3.013-9.442 1.266s-6.758-5.146-5.737-7.595 5.243-3.018 9.434-1.271 6.767 5.15 5.746 7.6h-.001z" class="D"/><path d="M145.528 218.948l2.374 1.535c.4.254.352.624-.074.622l-2.569-.019c-.165 0-.297.062-.331.164l-.609 1.579c-.107.257-.675.196-.973-.114l-1.781-1.815a.9.9 0 0 0-.475-.257l-2.751-.562c-.465-.097-.763-.503-.53-.688l1.445-1.133c.048-.037.079-.091.088-.151s-.006-.121-.041-.17l-1.096-1.919c-.183-.329.211-.507.65-.324l2.691 1.122c.157.071.334.09.503.054l2.074-.616c.187-.043.383-.017.553.072a.81.81 0 0 1 .374.412l.205 1.839c.018.077.052.149.099.213a.57.57 0 0 0 .176.155h0l-.002.001z" class="C"/><path d="M147.623 266.948c3.037-5.26 3.007-10.965-.062-12.737l2.734 1.579c3.069 1.772 3.098 7.476.061 12.737s-7.992 8.087-11.061 6.315l-2.734-1.579c3.069 1.772 8.025-1.054 11.062-6.315h0z" class="F"/><path d="M147.623 266.948c3.037-5.26 3.007-10.965-.062-12.737s-8.024 1.055-11.061 6.315-3.008 10.965.061 12.737 8.025-1.054 11.062-6.315zm-1.402-.809c2.27-3.932 2.252-8.2-.045-9.526s-6.004.791-8.274 4.723-2.247 8.192.051 9.519 5.998-.785 8.268-4.716h0z" class="B E"/><path d="M146.176 256.612c2.297 1.327 2.315 5.595.045 9.527s-5.971 6.042-8.268 4.716-2.321-5.587-.051-9.519 5.975-6.051 8.273-4.724h.001z" class="F"/><path d="M142.095 260.856l1.827-2.157c.303-.364.664-.269.607.153l-.349 2.546c-.021.163.023.302.121.349l1.488.806c.241.139.107.695-.237.951l-2.028 1.534c-.148.11-.258.263-.316.438l-.91 2.656c-.155.449-.597.692-.75.437l-.938-1.578c-.031-.052-.08-.091-.139-.107a.23.23 0 0 0-.174.02l-2.043.84c-.35.14-.475-.274-.238-.686l1.458-2.525a.81.81 0 0 0 .118-.492l-.345-2.136c-.019-.191.032-.381.142-.539a.81.81 0 0 1 .457-.318l1.85.034c.078-.009.154-.033.223-.071s.129-.091.176-.155h0z" class="E"/><use xlink:href="#B" class="F"/><path d="M124 306.844c6.075 0 11-2.879 11-6.423S130.075 294 124 294s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.228-2.15 8.228-4.803s-3.688-4.803-8.228-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#C" class="F"/><use xlink:href="#D" class="E"/><use xlink:href="#B" x="6" y="9" class="F"/><path d="M130 315.844c6.075 0 11-2.879 11-6.423S136.075 303 130 303s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.228-2.15 8.228-4.803s-3.688-4.803-8.228-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#C" x="6" y="9" class="F"/><use xlink:href="#D" x="6" y="9" class="E"/><use xlink:href="#B" x="29" y="12" class="F"/><path d="M153 318.844c6.075 0 11-2.879 11-6.423S159.075 306 153 306s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.228-2.15 8.228-4.803s-3.688-4.803-8.228-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#C" x="29" y="12" class="F"/><use xlink:href="#D" x="29" y="12" class="E"/><use xlink:href="#E" class="F"/><path d="M165 304.844c6.074 0 11-2.879 11-6.423S171.074 292 165 292s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.227-2.15 8.227-4.803s-3.687-4.803-8.227-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#F" class="F"/><path d="M167.512 297.01l2.781.504c.467.081.565.44.171.603l-2.378.97c-.152.064-.251.172-.242.28l.045 1.691c0 .278-.548.44-.942.27l-2.342-.99c-.17-.073-.357-.092-.538-.054l-2.755.539c-.466.09-.898-.17-.754-.431l.898-1.601c.03-.053.038-.115.023-.174a.23.23 0 0 0-.104-.141l-1.75-1.349c-.295-.233 0-.549.476-.549h2.915c.173.005.343-.045.485-.143l1.678-1.367a.8.8 0 0 1 .537-.147.81.81 0 0 1 .504.237l.897 1.619c.046.064.105.118.172.158a.56.56 0 0 0 .223.075h0z" class="E"/><use xlink:href="#E" x="-6" y="7" class="F"/><path d="M159 311.844c6.074 0 11-2.879 11-6.423S165.074 299 159 299s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.227-2.15 8.227-4.803s-3.687-4.803-8.227-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#F" x="-6" y="7" class="F"/><path d="M161.512 304.01l2.781.504c.467.081.565.44.171.603l-2.378.97c-.152.064-.251.172-.242.28l.045 1.691c0 .278-.548.44-.942.27l-2.342-.99c-.17-.073-.357-.092-.538-.054l-2.755.539c-.466.09-.898-.17-.754-.431l.898-1.601c.03-.053.038-.115.023-.174s-.052-.11-.103-.141l-1.75-1.349c-.296-.233 0-.549.476-.549h2.915c.173.005.343-.045.485-.143l1.678-1.367a.8.8 0 0 1 .537-.147.81.81 0 0 1 .504.237l.897 1.619c.046.064.105.118.172.158a.56.56 0 0 0 .223.075h-.001z" class="E"/><path d="M189.764 174.008c0 14.364-19.951 26.008-44.562 26.008-24.343 0-44.127-11.392-44.555-25.54v6.928.356c0 14.38 19.951 26.022 44.562 26.022s44.562-11.641 44.562-26.022v-.356-7.581h-.008l.001.185z" fill="#2f2be1" class="B"/><path d="M144.5 194c19.054 0 34.5-8.954 34.5-20s-15.446-20-34.5-20-34.5 8.954-34.5 20 15.446 20 34.5 20z" fill="#232277"/><path d="M189.764 174.008c0 14.364-19.951 26.008-44.562 26.008s-44.562-11.644-44.562-26.008S120.591 148 145.202 148s44.562 11.644 44.562 26.008zM179 174c0 11.046-15.446 20-34.5 20s-34.5-8.954-34.5-20 15.446-20 34.5-20 34.5 8.954 34.5 20z" fill="#504df7" class="B"/><path d="M155.683 172.788l-12.188 3.486c-1.635.467-3.657-.207-3.774-1.258l-.864-7.836c-.103-.91.257-1.804 1.034-2.582l.602-.601c.55-.55 1.813-.725 2.816-.39l15.507 5.168c1.007.336 1.373 1.053.823 1.604l-.601.601c-.778.777-1.939 1.404-3.355 1.808z" fill="#7b78ff"/><path d="M133.955 172.081l12.187-3.485c1.635-.467 3.657.207 3.774 1.258l.865 7.835c.103.91-.258 1.805-1.036 2.583l-.601.601c-.55.55-1.813.725-2.817.39l-15.507-5.168c-1.006-.336-1.373-1.054-.823-1.604l.602-.601c.777-.777 1.939-1.404 3.356-1.809z" fill="#9fd2eb"/><path d="M149.915 169.853c-.116-1.051-2.138-1.725-3.773-1.258l-6.91 1.977.492 4.444c.117 1.051 2.139 1.725 3.774 1.258l6.91-1.977-.493-4.444z" fill="#11429f"/><defs><filter id="filter0_f" x="-32" y="200" width="355" height="239" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="35" result="effect1_foregroundBlur"/></filter><linearGradient id="background" x1="273.47" y1="-13.2813" x2="415.619" y2="339.655" gradientUnits="userSpaceOnUse"><stop stop-color="#0B0B16"/><stop offset="1" class="G"/></linearGradient><linearGradient id="divider" x1="1.47345e-06" y1="409" x2="298.995" y2="410.864" gradientUnits="userSpaceOnUse"><stop class="I"/><stop offset="0.5" class="J"/><stop offset="1" class="I"/></linearGradient><clipPath id="mainclip"><rect width="290" height="500" rx="20" fill="white"/></clipPath><path id="text-path-a" d="M40 10 h228 a12,12 0 0 1 12 12 v364 a12,12 0 0 1 -12 12 h-246 a12 12 0 0 1 -12 -12 v-364 a12 12 0 0 1 12 -12 z" /><path id="B" d="M124 306.844c6.075 0 11-2.879 11-6.423v3.158c0 3.544-4.925 6.421-11 6.421s-11-2.877-11-6.421v-3.158c0 3.544 4.926 6.423 11 6.423z"/><path id="C" d="M132.227 300.422c0 2.653-3.688 4.803-8.228 4.803s-8.218-2.15-8.218-4.803 3.678-4.803 8.218-4.803 8.228 2.15 8.228 4.803z"/><path id="D" d="M126.512 299.01l2.782.504c.466.081.565.44.171.603l-2.379.97c-.152.064-.25.172-.242.28l.046 1.691c0 .278-.548.44-.942.27l-2.342-.99c-.169-.073-.357-.092-.538-.054l-2.755.539c-.466.09-.898-.17-.754-.431l.898-1.601c.03-.053.038-.115.023-.174s-.052-.11-.103-.141l-1.75-1.349c-.296-.233 0-.549.476-.549h2.915c.173.005.342-.045.485-.143l1.677-1.367a.8.8 0 0 1 .538-.147.81.81 0 0 1 .504.237l.897 1.619a.57.57 0 0 0 .395.233h-.002z"/><path id="E" d="M165 304.844c6.074 0 11-2.879 11-6.423v3.158c0 3.544-4.926 6.421-11 6.421s-11-2.877-11-6.421v-3.158c0 3.544 4.926 6.423 11 6.423z"/><path id="F" d="M173.227 298.422c0 2.653-3.687 4.803-8.227 4.803s-8.218-2.15-8.218-4.803 3.678-4.803 8.218-4.803 8.227 2.15 8.227 4.803z"/></defs></svg>'
            )
        );

        return svg;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IPair} from './IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFactory {
    /* ===== EVENT ===== */

    /// @dev Emits when a new Timeswap Pair contract is created.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 used as collateral.
    /// @param pair The address of the Timeswap Pair contract created.
    event CreatePair(IERC20 indexed asset, IERC20 indexed collateral, IPair pair);

    /// @dev Emits when a new pending owner is set.
    /// @param pendingOwner The address of the new pending owner.
    event SetOwner(address indexed pendingOwner);

    /// @dev Emits when the pending owner has accepted being the new owner.
    /// @param owner The address of the new owner.
    event AcceptOwner(address indexed owner);

    /* ===== VIEW ===== */

    /// @dev Return the address that receives the protocol fee.
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @dev Return the new pending address to replace the owner.
    /// @return The address of the pending owner.
    function pendingOwner() external view returns (address);

    /// @dev Return the fee per second earned by liquidity providers.
    /// @dev Must be downcasted to uint16.
    /// @return The fee following UQ0.40 format.
    function fee() external view returns (uint256);

    /// @dev Return the protocol fee per second earned by the owner.
    /// @dev Must be downcasted to uint16.
    /// @return The protocol fee per second following UQ0.40 format.
    function protocolFee() external view returns (uint256);

    /// @dev Returns the address of a deployed pair.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 used as collateral.
    /// @return pair The address of the Timeswap Pair contract.
    function getPair(IERC20 asset, IERC20 collateral) external view returns (IPair pair);

    /* ===== UPDATE ===== */

    /// @dev Creates a Timeswap Pool based on ERC20 pair parameters.
    /// @dev Cannot create a Timeswap Pool with the same pair parameters.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 as the collateral.
    /// @return pair The address of the Timeswap Pair contract.
    function createPair(IERC20 asset, IERC20 collateral) external returns (IPair pair);

    /// @dev Set the pending owner of the factory.
    /// @dev Can only be called by the current owner.
    /// @param _pendingOwner the chosen pending owner.
    function setPendingOwner(address _pendingOwner) external;

    /// @dev Set the pending owner as the owner of the factory.
    /// @dev Reset the pending owner to zero.
    /// @dev Can only be called by the pending owner.
    function acceptOwner() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}