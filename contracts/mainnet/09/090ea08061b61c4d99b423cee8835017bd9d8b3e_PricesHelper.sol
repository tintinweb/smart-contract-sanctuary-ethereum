/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);

    function getNormalizedValueUsdc(address tokensAddress, uint256 amount)
        external
        view
        returns (uint256);
}

interface IYearnAddressesProvider {
    function addressById(string memory) external view returns (address);
}

contract Ownable {
    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }
}

contract PricesHelper is Ownable {
    address public yearnAddressesProviderAddress;

    struct TokenPrice {
        address tokenId;
        uint256 priceUsdc;
    }

    struct TokenAmount {
        address tokenId;
        uint256 amount;
    }

    constructor(address _yearnAddressesProviderAddress) {
        require(
            _yearnAddressesProviderAddress != address(0),
            "Missing yearn addresses provider address"
        );
        yearnAddressesProviderAddress = _yearnAddressesProviderAddress;
    }

    function tokensPrices(address[] memory tokensAddresses)
        external
        view
        returns (TokenPrice[] memory)
    {
        TokenPrice[] memory _tokensPrices = new TokenPrice[](
            tokensAddresses.length
        );
        for (
            uint256 tokenIdx = 0;
            tokenIdx < tokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = tokensAddresses[tokenIdx];
            _tokensPrices[tokenIdx] = TokenPrice({
                tokenId: tokenAddress,
                priceUsdc: IOracle(getOracleAddress()).getPriceUsdcRecommended(
                    tokenAddress
                )
            });
        }
        return _tokensPrices;
    }

    function tokensPricesNormalizedUsdc(TokenAmount[] memory tokens)
        external
        view
        returns (TokenPrice[] memory)
    {
        TokenPrice[] memory _tokenPricesNormalized = new TokenPrice[](
            tokens.length
        );
        for (uint256 tokenIdx = 0; tokenIdx < tokens.length; tokenIdx++) {
            address tokenAddress = tokens[tokenIdx].tokenId;
            uint256 amount = tokens[tokenIdx].amount;
            _tokenPricesNormalized[tokenIdx] = TokenPrice({
                tokenId: tokenAddress,
                priceUsdc: IOracle(getOracleAddress()).getNormalizedValueUsdc(
                    tokenAddress,
                    amount
                )
            });
        }
        return _tokenPricesNormalized;
    }

    function getOracleAddress() internal view returns (address) {
        return
            IYearnAddressesProvider(yearnAddressesProviderAddress).addressById(
                "ORACLE"
            );
    }

    function updateYearnAddressesProviderAddress(
        address _yearnAddressesProviderAddress
    ) external onlyOwner {
        yearnAddressesProviderAddress = _yearnAddressesProviderAddress;
    }
}