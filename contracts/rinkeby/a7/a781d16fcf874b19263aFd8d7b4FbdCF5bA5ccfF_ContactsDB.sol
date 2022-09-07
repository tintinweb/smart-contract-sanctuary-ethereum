// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContactsDB {
    address[] internal ContactsAdmins;
    address[] internal PartiesAddresses;
    string[] public Countries;
    string[] public Roles;
    address internal owner;
    mapping(address => bytes32) internal AddressToPub;
    mapping(address => uint256) internal AddressToRole;
    mapping(address => uint256[]) internal AddressToCountries;

    constructor() public {
        owner = msg.sender;
        Countries.push("Afghanistan");
        Countries.push("Albania");
        Countries.push("Algeria");
        Countries.push("Andorra");
        Countries.push("Angola");
        Countries.push("Antigua and Barbuda");
        Countries.push("Argentina");
        Countries.push("Armenia");
        Countries.push("Australia");
        Countries.push("Austria");
        Countries.push("Azerbaijan");
        Countries.push("Bahamas");
        Countries.push("Bahrain");
        Countries.push("Bangladesh");
        Countries.push("Barbados");
        Countries.push("Belarus");
        Countries.push("Belgium");
        Countries.push("Belize");
        Countries.push("Benin");
        Countries.push("Bhutan");
        Countries.push("Bolivia");
        Countries.push("Bosnia and Herzegovina");
        Countries.push("Botswana");
        Countries.push("Brazil");
        Countries.push("Brunei");
        Countries.push("Bulgaria");
        Countries.push("Burkina Faso");
        Countries.push("Burundi");
        Countries.push("Cote d'Ivoire");
        Countries.push("Cabo Verde");
        Countries.push("Cambodia");
        Countries.push("Cameroon");
        Countries.push("Canada");
        Countries.push("Central African Republic");
        Countries.push("Chad");
        Countries.push("Chile");
        Countries.push("China");
        Countries.push("Colombia");
        Countries.push("Comoros");
        Countries.push("Congo (Congo-Brazzaville)");
        Countries.push("Costa Rica");
        Countries.push("Croatia");
        Countries.push("Cuba");
        Countries.push("Cyprus");
        Countries.push("Czechia (Czech Republic)");
        Countries.push("Democratic Republic of the Congo");
        Countries.push("Denmark");
        Countries.push("Djibouti");
        Countries.push("Dominica");
        Countries.push("Dominican Republic");
        Countries.push("Ecuador");
        Countries.push("Egypt");
        Countries.push("El Salvador");
        Countries.push("Equatorial Guinea");
        Countries.push("Eritrea");
        Countries.push("Estonia");
        Countries.push("Eswatini (fmr. 'Swaziland')");
        Countries.push("Ethiopia");
        Countries.push("Fiji");
        Countries.push("Finland");
        Countries.push("France");
        Countries.push("Gabon");
        Countries.push("Gambia");
        Countries.push("Georgia");
        Countries.push("Germany");
        Countries.push("Ghana");
        Countries.push("Greece");
        Countries.push("Grenada");
        Countries.push("Guatemala");
        Countries.push("Guinea");
        Countries.push("Guinea-Bissau");
        Countries.push("Guyana");
        Countries.push("Haiti");
        Countries.push("Holy See");
        Countries.push("Honduras");
        Countries.push("Hungary");
        Countries.push("Iceland");
        Countries.push("India");
        Countries.push("Indonesia");
        Countries.push("Iran");
        Countries.push("Iraq");
        Countries.push("Ireland");
        Countries.push("Israel");
        Countries.push("Italy");
        Countries.push("Jamaica");
        Countries.push("Japan");
        Countries.push("Jordan");
        Countries.push("Kazakhstan");
        Countries.push("Kenya");
        Countries.push("Kiribati");
        Countries.push("Kuwait");
        Countries.push("Kyrgyzstan");
        Countries.push("Laos");
        Countries.push("Latvia");
        Countries.push("Lebanon");
        Countries.push("Lesotho");
        Countries.push("Liberia");
        Countries.push("Libya");
        Countries.push("Liechtenstein");
        Countries.push("Lithuania");
        Countries.push("Luxembourg");
        Countries.push("Madagascar");
        Countries.push("Malawi");
        Countries.push("Malaysia");
        Countries.push("Maldives");
        Countries.push("Mali");
        Countries.push("Malta");
        Countries.push("Marshall Islands");
        Countries.push("Mauritania");
        Countries.push("Mauritius");
        Countries.push("Mexico");
        Countries.push("Micronesia");
        Countries.push("Moldova");
        Countries.push("Monaco");
        Countries.push("Mongolia");
        Countries.push("Montenegro");
        Countries.push("Morocco");
        Countries.push("Mozambique");
        Countries.push("Myanmar (formerly Burma)");
        Countries.push("Namibia");
        Countries.push("Nauru");
        Countries.push("Nepal");
        Countries.push("Netherlands");
        Countries.push("New Zealand");
        Countries.push("Nicaragua");
        Countries.push("Niger");
        Countries.push("Nigeria");
        Countries.push("North Korea");
        Countries.push("North Macedonia");
        Countries.push("Norway");
        Countries.push("Oman");
        Countries.push("Pakistan");
        Countries.push("Palau");
        Countries.push("Palestine State");
        Countries.push("Panama");
        Countries.push("Papua New Guinea");
        Countries.push("Paraguay");
        Countries.push("Peru");
        Countries.push("Philippines");
        Countries.push("Poland");
        Countries.push("Portugal");
        Countries.push("Qatar");
        Countries.push("Romania");
        Countries.push("Russia");
        Countries.push("Rwanda");
        Countries.push("Saint Kitts and Nevis");
        Countries.push("Saint Lucia");
        Countries.push("Saint Vincent and the Grenadines");
        Countries.push("Samoa");
        Countries.push("San Marino");
        Countries.push("Sao Tome and Principe");
        Countries.push("Saudi Arabia");
        Countries.push("Senegal");
        Countries.push("Serbia");
        Countries.push("Seychelles");
        Countries.push("Sierra Leone");
        Countries.push("Singapore");
        Countries.push("Slovakia");
        Countries.push("Slovenia");
        Countries.push("Solomon Islands");
        Countries.push("Somalia");
        Countries.push("South Africa");
        Countries.push("South Korea");
        Countries.push("South Sudan");
        Countries.push("Spain");
        Countries.push("Sri Lanka");
        Countries.push("Sudan");
        Countries.push("Suriname");
        Countries.push("Sweden");
        Countries.push("Switzerland");
        Countries.push("Syria");
        Countries.push("Tajikistan");
        Countries.push("Tanzania");
        Countries.push("Thailand");
        Countries.push("Timor-Leste");
        Countries.push("Togo");
        Countries.push("Tonga");
        Countries.push("Trinidad and Tobago");
        Countries.push("Tunisia");
        Countries.push("Turkiye");
        Countries.push("Turkmenistan");
        Countries.push("Tuvalu");
        Countries.push("Uganda");
        Countries.push("Ukraine");
        Countries.push("United Arab Emirates");
        Countries.push("United Kingdom");
        Countries.push("United States of America");
        Countries.push("Uruguay");
        Countries.push("Uzbekistan");
        Countries.push("Vanuatu");
        Countries.push("Venezuela");
        Countries.push("Vietnam");
        Countries.push("Yemen");
        Countries.push("Zambia");
        Countries.push("Zimbabwe");

        Roles.push("NONE");
        Roles.push("CUSTOMER");
        Roles.push("PRODUCER");
        Roles.push("BANK");
        Roles.push("SHIPPER");
        Roles.push("CUSTOMS");
        Roles.push("INSPECTOR");
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function AddAddress(
        address _address,
        uint256 _role,
        uint256[] memory _countries,
        bytes32 _pub
    ) public onlyOwner {
        AddressToRole[_address] = _role;
        for (uint256 i = 0; i < _countries.length; i++) {
            AddressToCountries[_address].push(_countries[i]);
        }
        AddressToPub[_address] = _pub;
        PartiesAddresses.push(_address);
    }

    function GetAddressPub(address _address) public view returns (bytes32) {
        require(AddressToPub[_address] > 0, "Address Not Found!");
        return (AddressToPub[_address]);
    }

    function GetAddressRole(address _address)
        public
        view
        returns (string memory)
    {
        require(AddressToRole[_address] > 0, "Address Not Found!");
        return (Roles[AddressToRole[_address]]);
    }

    function GetAddressesByCountries(uint256 _country, uint256 _Role)
        public
        view
        returns (address[] memory _AddressesByCountries)
    {
        address[] memory AddressArray;
        uint256 arrindex = 0;
        uint256 arrindex2 = 0;
        for (uint256 i = 0; i < PartiesAddresses.length; i++) {
            if (AddressToRole[PartiesAddresses[i]] == _Role) {
                AddressArray[arrindex] = PartiesAddresses[i];
                arrindex++;
            }
        }
        for (uint256 i = 0; i < AddressArray.length; i++) {
            for (
                uint256 ii = 0;
                ii < AddressToCountries[AddressArray[i]].length;
                ii++
            ) {
                if (AddressToCountries[AddressArray[i]][ii] == _country) {
                    _AddressesByCountries[arrindex2] = AddressArray[i];
                    arrindex2++;
                }
            }
        }
        return _AddressesByCountries;
    }
}