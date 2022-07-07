/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

contract Nft {
    string public constant NFT_NAME = "Nfts de Mati";

    uint256 public constant PRICE = 50000000000000000; //0.05 eth

    address public immutable i_owner;

    address[] public users;

    nftInfo[] public nft;

    uint8 private claimCounter;

    mapping(address => bool) public hasAccount;

    mapping(uint8 => address) public NftToAddress;

    mapping(address => uint8) public NumberOfNfts;

    constructor() {
        i_owner = msg.sender;
        claimCounter = 0;
    }

    struct nftInfo {
        uint256 id;
        string background;
        string tie;
        string suit;
        string base;
        string dna;
        string cid;
        address owner;
    }

    function mint(
        string memory _background,
        string memory _tie,
        string memory _suit,
        string memory _base,
        string memory _dna,
        string memory _cid
    ) public onlyOwner {
        nft.push(
            nftInfo(
                nft.length,
                _background,
                _tie,
                _suit,
                _base,
                _dna,
                _cid,
                address(0)
            )
        );
    }

    function claimNft() public payable exactlyCost {
        if (nft.length <= claimCounter) {
            revert("Sorry, there are no more nfts");
        }
        if (hasAccount[msg.sender] == false) {
            users.push(msg.sender);
            hasAccount[msg.sender] = true;
        }
        nft[claimCounter].owner = msg.sender;
        NftToAddress[claimCounter] = msg.sender;
        NumberOfNfts[msg.sender]++;
        emit Claim(msg.sender, claimCounter);
        claimCounter++;
    }

    function transfer(uint8 _id, address _to) public nftOwner(_id) {
        if (hasAccount[_to] == false) {
            users.push(_to);
            hasAccount[_to] = true;
        }
        nft[_id].owner = _to;
        NftToAddress[_id] = _to;
        NumberOfNfts[msg.sender] = NumberOfNfts[msg.sender] - 1;
        NumberOfNfts[_to]++;
        emit Transfer(msg.sender, _to, _id);
    }

    function burn(uint8 _id) public nftOwner(_id) {
        nft[_id].owner = address(0);
        NftToAddress[_id] = address(0);
        NumberOfNfts[msg.sender] = NumberOfNfts[msg.sender] - 1;
        emit Burn(msg.sender, _id);
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Transaction reverted");
    }

    modifier exactlyCost() {
        if (msg.value == PRICE) {
            _;
        } else {
            revert("You must send 0.05 eth");
        }
    }

    modifier onlyOwner() {
        if (msg.sender == i_owner) {
            _;
        } else {
            revert(
                "You must be the deployer of the contract to run this function"
            );
        }
    }

    modifier nftOwner(uint8 _id) {
        if (msg.sender == NftToAddress[_id]) {
            _;
        } else {
            revert("To transfer the NFT you must be the owner");
        }
    }

    receive() external payable {
        claimNft();
    }

    fallback() external payable {
        claimNft();
    }

    event Transfer(address indexed _from, address indexed _to, uint8 _id);
    event Claim(address indexed _to, uint8 _id);
    event Burn(address indexed _from, uint8 _id);
}