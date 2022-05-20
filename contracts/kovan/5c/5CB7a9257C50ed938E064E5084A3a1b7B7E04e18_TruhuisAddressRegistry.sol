// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

import "Ownable.sol";
import "TruhuisAddressRegistryStateGovernment.sol";

contract TruhuisAddressRegistry is Ownable, TruhuisAddressRegistryStateGovernment {
    //// Potential addresses
    //address public appraiser;
    //address public bank;
    //address public homeInspector;
    //address public notary;
    //address public mortgagee;

    address public auction;
    address public currencyRegistry;
    address public cadastre;
    address public marketplace;

    event UpdatedAuction(
        address indexed oldAddr,
        address indexed newAddr
    );

    event UpdatedCurrencyRegistry(
        address indexed oldAddr,
        address indexed newAddr
    );

    event UpdatedCadastre(
        address indexed oldAddr,
        address indexed newAddr
    );

    event UpdatedMarketplace(
        address indexed oldAddr,
        address indexed newAddr
    );

    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    function updateCurrencyRegistry(address _currencyRegistry) external onlyOwner {
        currencyRegistry = _currencyRegistry;
    }

    function updateCadastre(address _cadastre) external onlyOwner {
        cadastre = _cadastre;
    }

    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     * @param _country Country ISO 3166-1 Alpha-3 code (e.g. "NLD" or "DEU").
     */
    function stateGovernment(string memory _country) external view returns (address) {
        return s_stateGovernments[bytes3(bytes(_country))].stateGovernment;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

import "Ownable.sol";
import { Country } from "Country.sol";

contract TruhuisAddressRegistryStateGovernment is Ownable {
    struct StateGovernment {
        bool isRegistered;
        address stateGovernment;
        bytes3 country;
    }

    mapping(bytes3 => StateGovernment) public s_stateGovernments;

    event StateGovernmentRegistered(address stateGovernment, bytes3 country);
    event UpdatedStateGovernment(address oldAddr, address newAddr, bytes3 country);

    modifier notRegisteredGovernemnt(address _stateGovernment, bytes3 _country) {
        StateGovernment memory stateGov = s_stateGovernments[_country];

        require(stateGov.isRegistered == false, "already registered");
        require(stateGov.stateGovernment != _stateGovernment, "provided identical stateGov");
        require(stateGov.country != _country, "provided identical country");

        _;
    }

    function updateStateGovernment(address _newAddr, bytes3 _country)
        public 
        onlyOwner
    {
        StateGovernment storage s_stateGovernment = s_stateGovernments[_country];

        address oldAddr = s_stateGovernment.stateGovernment;

        require(oldAddr != _newAddr, "provided the same address");

        s_stateGovernment.isRegistered = true;
        s_stateGovernment.stateGovernment = _newAddr;
        s_stateGovernment.country = _country;

        emit UpdatedStateGovernment(oldAddr, _newAddr, _country);
    }

    function registerStateGovernment(address _stateGovernment, bytes3 _country)
        public
        onlyOwner
        notRegisteredGovernemnt(_stateGovernment, _country)
    {
        _registerStateGovernment(_stateGovernment, _country);
    }

    function _registerStateGovernment(address _stateGovernment, bytes3 _country)
        private
    {
        require(_stateGovernment != address(0), "invalid zero address");

        s_stateGovernments[_country] = StateGovernment({
            isRegistered: true,
            stateGovernment: _stateGovernment,
            country: _country
        });

        emit StateGovernmentRegistered(_stateGovernment, _country);
    }
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

library Country {
    function getCountries() public pure returns (bytes3[249] memory) {
        return [
            bytes3(bytes("AFG")), 
            bytes3(bytes("ALA")),
            bytes3(bytes("ALB")),
            bytes3(bytes("DZA")),
            bytes3(bytes("ASM")),
            bytes3(bytes("AND")),
            bytes3(bytes("AGO")),
            bytes3(bytes("AIA")),
            bytes3(bytes("ATA")),
            bytes3(bytes("ATG")),
            bytes3(bytes("ARG")),
            bytes3(bytes("ARM")),
            bytes3(bytes("ABW")),
            bytes3(bytes("AUS")),
            bytes3(bytes("AUT")),
            bytes3(bytes("AZE")),
            bytes3(bytes("BHS")),
            bytes3(bytes("BHR")),
            bytes3(bytes("BGD")),
            bytes3(bytes("BRB")),
            bytes3(bytes("BLR")),
            bytes3(bytes("BEL")),
            bytes3(bytes("BLZ")),
            bytes3(bytes("BEN")),
            bytes3(bytes("BMU")),
            bytes3(bytes("BTN")),
            bytes3(bytes("BOL")),
            bytes3(bytes("BES")),
            bytes3(bytes("BIH")),
            bytes3(bytes("BWA")),
            bytes3(bytes("BVT")),
            bytes3(bytes("BRA")),
            bytes3(bytes("IOT")),
            bytes3(bytes("BRN")),
            bytes3(bytes("BGR")),
            bytes3(bytes("BFA")),
            bytes3(bytes("BDI")),
            bytes3(bytes("CPV")),
            bytes3(bytes("KHM")),
            bytes3(bytes("CMR")),
            bytes3(bytes("CAN")),
            bytes3(bytes("CYM")),
            bytes3(bytes("CAF")),
            bytes3(bytes("TCD")),
            bytes3(bytes("CHL")),
            bytes3(bytes("CHN")),
            bytes3(bytes("CXR")),
            bytes3(bytes("CCK")),
            bytes3(bytes("COL")),
            bytes3(bytes("COM")),
            bytes3(bytes("COD")),
            bytes3(bytes("COG")),
            bytes3(bytes("COK")),
            bytes3(bytes("CRI")),
            bytes3(bytes("CIV")),
            bytes3(bytes("HRV")),
            bytes3(bytes("CUB")),
            bytes3(bytes("CUW")),
            bytes3(bytes("CYP")),
            bytes3(bytes("CZE")),
            bytes3(bytes("DNK")),
            bytes3(bytes("DJI")),
            bytes3(bytes("DMA")),
            bytes3(bytes("DOM")),
            bytes3(bytes("ECU")),
            bytes3(bytes("EGY")),
            bytes3(bytes("SLV")),
            bytes3(bytes("GNQ")),
            bytes3(bytes("ERI")),
            bytes3(bytes("EST")),
            bytes3(bytes("SWZ")),
            bytes3(bytes("ETH")),
            bytes3(bytes("FLK")),
            bytes3(bytes("FRO")),
            bytes3(bytes("FJI")),
            bytes3(bytes("FIN")),
            bytes3(bytes("FRA")),
            bytes3(bytes("GUF")),
            bytes3(bytes("PYF")),
            bytes3(bytes("ATF")),
            bytes3(bytes("GAB")),
            bytes3(bytes("GMB")),
            bytes3(bytes("GEO")),
            bytes3(bytes("DEU")),
            bytes3(bytes("GHA")),
            bytes3(bytes("GIB")),
            bytes3(bytes("GRC")),
            bytes3(bytes("GRL")),
            bytes3(bytes("GRD")),
            bytes3(bytes("GLP")),
            bytes3(bytes("GUM")),
            bytes3(bytes("GTM")),
            bytes3(bytes("GGY")),
            bytes3(bytes("GIN")),
            bytes3(bytes("GNB")),
            bytes3(bytes("GUY")),
            bytes3(bytes("HTI")),
            bytes3(bytes("HMD")),
            bytes3(bytes("VAT")),
            bytes3(bytes("HND")),
            bytes3(bytes("HKG")),
            bytes3(bytes("HUN")),
            bytes3(bytes("ISL")),
            bytes3(bytes("IND")),
            bytes3(bytes("IDN")),
            bytes3(bytes("IRN")),
            bytes3(bytes("IRQ")),
            bytes3(bytes("IRL")),
            bytes3(bytes("IMN")),
            bytes3(bytes("ISR")),
            bytes3(bytes("ITA")),
            bytes3(bytes("JAM")),
            bytes3(bytes("JPN")),
            bytes3(bytes("JEY")),
            bytes3(bytes("JOR")),
            bytes3(bytes("KAZ")),
            bytes3(bytes("KEN")),
            bytes3(bytes("KIR")),
            bytes3(bytes("PRK")),
            bytes3(bytes("KOR")),
            bytes3(bytes("KWT")),
            bytes3(bytes("KGZ")),
            bytes3(bytes("LAO")),
            bytes3(bytes("LVA")),
            bytes3(bytes("LBN")),
            bytes3(bytes("LSO")),
            bytes3(bytes("LBR")),
            bytes3(bytes("LBY")),
            bytes3(bytes("LIE")),
            bytes3(bytes("LTU")),
            bytes3(bytes("LUX")),
            bytes3(bytes("MAC")),
            bytes3(bytes("MKD")),
            bytes3(bytes("MDG")),
            bytes3(bytes("MWI")),
            bytes3(bytes("MYS")),
            bytes3(bytes("MDV")),
            bytes3(bytes("MLI")),
            bytes3(bytes("MLT")),
            bytes3(bytes("MHL")),
            bytes3(bytes("MTQ")),
            bytes3(bytes("MRT")),
            bytes3(bytes("MUS")),
            bytes3(bytes("MYT")),
            bytes3(bytes("MEX")),
            bytes3(bytes("FSM")),
            bytes3(bytes("MDA")),
            bytes3(bytes("MCO")),
            bytes3(bytes("MNG")),
            bytes3(bytes("MNE")),
            bytes3(bytes("MSR")),
            bytes3(bytes("MAR")),
            bytes3(bytes("MOZ")),
            bytes3(bytes("MMR")),
            bytes3(bytes("NAM")),
            bytes3(bytes("NRU")),
            bytes3(bytes("NPL")),
            bytes3(bytes("NLD")),
            bytes3(bytes("NCL")),
            bytes3(bytes("NZL")),
            bytes3(bytes("NIC")),
            bytes3(bytes("NER")),
            bytes3(bytes("NGA")),
            bytes3(bytes("NIU")),
            bytes3(bytes("NFK")),
            bytes3(bytes("MNP")),
            bytes3(bytes("NOR")),
            bytes3(bytes("OMN")),
            bytes3(bytes("PAK")),
            bytes3(bytes("PLW")),
            bytes3(bytes("PSE")),
            bytes3(bytes("PAN")),
            bytes3(bytes("PNG")),
            bytes3(bytes("PRY")),
            bytes3(bytes("PER")),
            bytes3(bytes("PHL")),
            bytes3(bytes("PCN")),
            bytes3(bytes("POL")),
            bytes3(bytes("PRT")),
            bytes3(bytes("PRI")),
            bytes3(bytes("QAT")),
            bytes3(bytes("REU")),
            bytes3(bytes("ROU")),
            bytes3(bytes("RUS")),
            bytes3(bytes("RWA")),
            bytes3(bytes("BLM")),
            bytes3(bytes("SHN")),
            bytes3(bytes("KNA")),
            bytes3(bytes("LCA")),
            bytes3(bytes("MAF")),
            bytes3(bytes("SPM")),
            bytes3(bytes("VCT")),
            bytes3(bytes("WSM")),
            bytes3(bytes("SMR")),
            bytes3(bytes("STP")),
            bytes3(bytes("SAU")),
            bytes3(bytes("SEN")),
            bytes3(bytes("SRB")),
            bytes3(bytes("SYC")),
            bytes3(bytes("SLE")),
            bytes3(bytes("SGP")),
            bytes3(bytes("SXM")),
            bytes3(bytes("SVK")),
            bytes3(bytes("SVN")),
            bytes3(bytes("SLB")),
            bytes3(bytes("SOM")),
            bytes3(bytes("ZAF")),
            bytes3(bytes("SGS")),
            bytes3(bytes("SSD")),
            bytes3(bytes("ESP")),
            bytes3(bytes("LKA")),
            bytes3(bytes("SDN")),
            bytes3(bytes("SUR")),
            bytes3(bytes("SJM")),
            bytes3(bytes("SWE")),
            bytes3(bytes("CHE")),
            bytes3(bytes("SYR")),
            bytes3(bytes("TWN")),
            bytes3(bytes("TJK")),
            bytes3(bytes("TZA")),
            bytes3(bytes("THA")),
            bytes3(bytes("TLS")),
            bytes3(bytes("TGO")),
            bytes3(bytes("TKL")),
            bytes3(bytes("TON")),
            bytes3(bytes("TTO")),
            bytes3(bytes("TUN")),
            bytes3(bytes("TUR")),
            bytes3(bytes("TKM")),
            bytes3(bytes("TCA")),
            bytes3(bytes("TUV")),
            bytes3(bytes("UGA")),
            bytes3(bytes("UKR")),
            bytes3(bytes("ARE")),
            bytes3(bytes("GBR")),
            bytes3(bytes("UMI")),
            bytes3(bytes("USA")),
            bytes3(bytes("URY")),
            bytes3(bytes("UZB")),
            bytes3(bytes("VUT")),
            bytes3(bytes("VEN")),
            bytes3(bytes("VNM")),
            bytes3(bytes("VGB")),
            bytes3(bytes("VIR")),
            bytes3(bytes("WLF")),
            bytes3(bytes("ESH")),
            bytes3(bytes("YEM")),
            bytes3(bytes("ZMB")),
            bytes3(bytes("ZWE"))
        ];
    }
}