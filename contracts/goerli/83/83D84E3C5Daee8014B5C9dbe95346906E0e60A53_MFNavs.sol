// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract MFNavs {
    // Current lineup of funds
    mapping(string => Fund) private s_funds;
    // Nightly NAV storage
    mapping(string => Nav) private s_navs;

    string private latestDate;

    // Static fund data
    string private constant FUND_NAME =
        "Legg Mason Westen Asset Macro Opportunities Bond Fund";

    string private constant CLASS_A_NAME = "CLASS A US$ ACCUMULATING";
    string private constant CLASS_B_NAME = "CLASS B US$ ACCUMULATING";
    string private constant CLASS_C_NAME = "CLASS C US$ ACCUMULATING";

    string private constant ISIN_A = "IE00BC9S3Z47";
    string private constant ISIN_B = "IE00BKZGYJ98";
    string private constant ISIN_C = "IE00BKZGYL11";

    string private constant CUSIP_A = "G5447A753";
    string private constant CUSIP_B = "G5S46W768";
    string private constant CUSIP_C = "G5S46W784";

    struct Fund {
        string fundName;
        string className;
        string isin;
        string cusip;
    }

    struct Nav {
        string date;
        string time;
        uint256 nav;
        Fund fund;
    }

    constructor() {
        // Initialize available funds
        s_funds[ISIN_A] = Fund(FUND_NAME, CLASS_A_NAME, ISIN_A, CUSIP_A);
        s_funds[ISIN_B] = Fund(FUND_NAME, CLASS_B_NAME, ISIN_B, CUSIP_B);
        s_funds[ISIN_C] = Fund(FUND_NAME, CLASS_C_NAME, ISIN_C, CUSIP_C);
    }

    function decodePayload(
        bytes calldata payload
    )
        external
        returns (
            string memory _date,
            string memory _time,
            string memory _isin,
            uint256 _nav
        )
    {
        (_date, _time, _isin, _nav) = abi.decode(
            payload,
            (string, string, string, uint256)
        );

        latestDate = _date;

        s_navs[string.concat(_isin, "-", _date)] = Nav(
            _date,
            _time,
            _nav,
            s_funds[_isin]
        );
    }

    function getHistoricalNav(
        string memory _isinInput,
        string memory _dateInput
    )
        public
        view
        returns (
            string memory _fundName,
            string memory _shareClass,
            string memory _isin,
            string memory _cusip,
            string memory _date,
            string memory _time,
            uint256 _nav
        )
    {
        Nav memory nav = s_navs[string.concat(_isinInput, "-", _dateInput)];
        return (
            nav.fund.fundName,
            nav.fund.className,
            nav.fund.isin,
            nav.fund.cusip,
            nav.date,
            nav.time,
            nav.nav
        );
    }

    function getCurrentNavs()
        public
        view
        returns (Nav memory, Nav memory, Nav memory)
    {
        return (
            s_navs[string.concat(ISIN_A, "-", latestDate)],
            s_navs[string.concat(ISIN_B, "-", latestDate)],
            s_navs[string.concat(ISIN_C, "-", latestDate)]
        );
    }
}