// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MyInfaq {
    struct Infaq {
        address owner;
        string name;
        string title;
        string description;
        uint256 target;
        uint256 duedate;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Infaq) public infaqs;

    uint256 public numberOfInfaqs = 0;


    //Function Master Data Infaq
    function createInfaq(address _owner,string memory _name, string memory _title, string memory _description, uint256 _target, uint256 _duedate, string memory _image) public returns (uint256) {
        Infaq storage infaq = infaqs[numberOfInfaqs];

        require(infaq.duedate < block.timestamp, "Tanggal Due Date harus melebihi tanggal sekarang.");

        infaq.owner = _owner;
        infaq.name = _name;
        infaq.title = _title;
        infaq.description = _description;
        infaq.target = _target;
        infaq.duedate = _duedate;
        infaq.amountCollected = 0;
        infaq.image = _image;

        numberOfInfaqs++;

        return numberOfInfaqs - 1;
    }

    //Function Kirim Infaq
    function kirimInfaq(uint256 _id) public payable {
        uint256 amount = msg.value;

        Infaq storage infaq = infaqs[_id];

        infaq.donators.push(msg.sender);
        infaq.donations.push(amount);

        (bool sent,) = payable(infaq.owner).call{value: amount}("");

        if(sent) {
            infaq.amountCollected = infaq.amountCollected + amount;
        }
    }

    //Function Buat Ambil Data yang Siapa yg Infaq (Infaqers)
    function getInfaqers(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (infaqs[_id].donators, infaqs[_id].donations);
    }

    //Function Buat Ambil Data Semua Transaksi Infaq
    function getInfaqs() public view returns (Infaq[] memory) {
        Infaq[] memory allInfaqs = new Infaq[](numberOfInfaqs);

        for(uint i = 0; i < numberOfInfaqs; i++) {
            Infaq storage item = infaqs[i];

            allInfaqs[i] = item;
        }

        return allInfaqs;
    }
}