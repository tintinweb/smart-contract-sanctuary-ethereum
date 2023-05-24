// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

contract employees_records {
    int id;
    string f_name;
    string last_name;
    string address_;
    string mob_no;

    function store_information(
        int _id,
        string memory _f_name,
        string memory _last_name,
        string memory _address,
        string memory _mob_no
    ) public {
        id = _id;
        f_name = _f_name;
        last_name = _last_name;
        address_ = _address;
        mob_no = _mob_no;
    }

    function retrive_information()
        public
        view
        returns (
            int,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (id, f_name, last_name, address_, mob_no);
    }
}