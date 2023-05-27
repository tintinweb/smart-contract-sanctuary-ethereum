// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract OngContract2 {

    address public owner;
    uint public campaignCount;
    uint public ongCount;
    uint public campaignTax;
    uint public ongTax;
    uint public balance;
    statisticsStruct public statistics;
    campaignStruct[] campaigns;
    ongStruct[] ongs;

    mapping(address => campaignStruct[])  campaignsOf;
    mapping(address => ongStruct[])  ongsOf;
    mapping(uint => donatorsStruct[]) donatorsOf;
    mapping(uint => donatorsStruct[]) donatorsOfOng;
    mapping(uint => bool) public campaignExists;
    mapping(uint => bool) public ongExists;

        enum statusEnum {
        OPEN,
        APPROVED,
        REVERTED,
        DELETED,
        PAIDOUT
    }

    enum ongStatusEnum {
        ACTIVE,
        DELETED,
        PAIDOUT
    }


    struct campaignStruct {
        address owner;
        uint id;
        uint cost;
        uint raised;
        uint timestamp;
        uint deadline; 
        uint donators;
        string title; 
        string description;
        string image;
        statusEnum status;
    }

    struct ongStruct{
        address owner;
        uint id;
        uint raised;
        uint timestamp;
        uint donators;
        string name;
        string description;
        string image;
        ongStatusEnum status;
    }

 
    struct donatorsStruct {
        address owner;
        uint amount; 
        uint timestamp;
        bool refunding;
    }

       struct statisticsStruct {
        uint totalCampaigns;
        uint totalDonations;
        uint totalDonators;
        uint totalOngs;
    }


    modifier ownerOnly(){
        require(msg.sender == owner, "Owner reserved only");
        _;
    }

    

    event Action (
        uint id,
        uint timestamp,
        string actionType,
        address indexed executor
    );

    constructor (uint _campaignTax){
        owner = msg.sender;
        campaignTax = _campaignTax;
        ongTax = _campaignTax;
    }

  

    function createCampaign (
        string memory _title,
        string memory _description,
        string memory _image,
        uint _cost,
        uint _deadline
    ) public returns (bool) {

        require(bytes(_title).length > 0, "Title must not be empty");
        require(bytes(_description).length > 0, "Description must not be empty");
        require(bytes(_image).length > 0, "Image must not be empty");
        require(_cost > 0 ether, "Cost must be greater than 0");

        campaignStruct memory campaign;
        campaign.owner = msg.sender;
        campaign.id = campaignCount;
        campaign.title = _title;
        campaign.description = _description;
        campaign.image = _image;
        campaign.cost = _cost;
        campaign.deadline = _deadline;
        campaign.timestamp = block.timestamp;

        campaigns.push(campaign);
        campaignsOf[msg.sender].push(campaign);
        campaignExists[campaignCount] = true;
        statistics.totalCampaigns++;

        emit Action(campaignCount++, block.timestamp, "Campaign Created", msg.sender);

        return true;
    }

    function createOng(
        string memory _name,
        string memory _description,
        string memory _image
    ) public returns (bool) {

        require(bytes(_name).length > 0, "Name must not be empty");
        require(bytes(_description).length > 0, "Description must not be empty");
        require(bytes(_image).length > 0, "Image must not be empty");

        ongStruct memory ong;
        ong.owner = msg.sender;
        ong.id = ongCount;
        ong.name = _name;
        ong.description = _description;
        ong.image = _image;
        ong.timestamp = block.timestamp;

        ongs.push(ong);
        ongsOf[msg.sender].push(ong);
        ongExists[ongCount] = true;
        statistics.totalOngs++;

        emit Action(ongCount++, block.timestamp, "Ong Created", msg.sender);

        return true;
    }

    function updateCampaign(
        uint _id,
        string memory _title,
        string memory _description,
        string memory _image,
        uint _deadline
    ) public returns (bool) {

        require(msg.sender == campaigns[_id].owner, "Only owner can update");
        require(bytes(_title).length > 0, "Title must not be empty");
        require(bytes(_description).length > 0, "Description must not be empty");
        require(bytes(_image).length > 0, "Image must not be empty");

        campaigns[_id].title = _title;
        campaigns[_id].description = _description;
        campaigns[_id].image = _image;
        campaigns[_id].deadline = _deadline;

        emit Action(_id, block.timestamp, "Campaign Updated", msg.sender);

        return true;
    }

    function updateOng( 
        uint _id,
        string memory _name,
        string memory _description,
        string memory _image
    ) public returns (bool) {

        require(msg.sender == ongs[_id].owner, "Only owner can update");
        require(bytes(_name).length > 0, "Name must not be empty");
        require(bytes(_description).length > 0, "Description must not be empty");
        require(bytes(_image).length > 0, "Image must not be empty");

        ongs[_id].name = _name;
        ongs[_id].description = _description;
        ongs[_id].image = _image;

        emit Action(_id, block.timestamp, "Ong Updated", msg.sender);

        return true;
    }

    function deleteCampaign(
        uint _id
    ) public returns(bool){
            
            require(msg.sender == campaigns[_id].owner, "Only owner can delete");
            require(campaigns[_id].status == statusEnum.OPEN, "Campaign closed");
    
            campaigns[_id].status = statusEnum.DELETED;
    
            emit Action(_id, block.timestamp, "Campaign Deleted", msg.sender);
    
            return true;
    }

    function deleteOng (
        uint _id
    ) public returns (bool) {

        require(msg.sender == ongs[_id].owner, "Only owner can delete");
        require(ongs[_id].status == ongStatusEnum.ACTIVE, "Ong closed");

        ongs[_id].status = ongStatusEnum.DELETED;

        emit Action(_id, block.timestamp, "Ong Deleted", msg.sender);

        return true;
    }

   function payTo(
    address _to,
    uint _amount
   ) internal {

    (bool success, ) = payable(_to).call{value: _amount}("");
    require(success, "Failed to send Ether");
   }


    function refund(
        uint _id
    ) internal {

        for (uint i = 0; i < donatorsOf[_id].length; i++ ){
            address _owner = donatorsOf[_id][i].owner;
            uint _amount = donatorsOf[_id][i].amount;

            donatorsOf[_id][i].refunding = true;
            donatorsOf[_id][i].timestamp = block.timestamp;

            payTo(_owner, _amount);

            statistics.totalDonations -= _amount;
            statistics.totalDonators -= 1;
        }
    }
    

    function refundOng(
        uint _id
    ) internal {

        for (uint i = 0; i < donatorsOfOng[_id].length; i++ ){
            address _owner = donatorsOfOng[_id][i].owner;
            uint _amount = donatorsOfOng[_id][i].amount;

            donatorsOfOng[_id][i].refunding = true;
            donatorsOfOng[_id][i].timestamp = block.timestamp;

            payTo(_owner, _amount);

            statistics.totalDonations -= _amount;
            statistics.totalDonators -= 1;
        }
    }


    function payout(
        uint _id
    ) internal{

        uint raised = campaigns[_id].raised;
        uint tax = raised * campaignTax / 100;

        campaigns[_id].status = statusEnum.PAIDOUT;
        payTo(campaigns[_id].owner, raised - tax);
        payTo(owner, tax);
        balance -= raised;

        emit Action(_id, block.timestamp, "Campaign Payout", msg.sender);
    }


 
    function payoutOng (
        uint _id
    ) public returns (bool) {

        uint raised = ongs[_id].raised;
        uint tax = raised * ongTax / 100;

        ongs[_id].status = ongStatusEnum.PAIDOUT;
        payTo(ongs[_id].owner, raised - tax);
        payTo(owner, tax);
        balance -= raised;

        emit Action(_id, block.timestamp, "Ong Payout", msg.sender);

        return true;
    }




    function donateToCampaign(
        uint _id
    ) public payable returns(bool) {

        require(msg.value > 0 ether, "Donation must be greater than 0");
        require(campaignExists[_id], "Campaign does not exist");
        require(campaigns[_id].status == statusEnum.OPEN, "Campaign closed");

        statistics.totalDonations += msg.value;
        statistics.totalDonators += 1;
        campaigns[_id].raised += msg.value;
        campaigns[_id].donators += 1;

        donatorsOf[_id].push(donatorsStruct(msg.sender, msg.value, block.timestamp, false));

        emit Action(_id, block.timestamp, "Donation to campaign", msg.sender);

        if (campaigns[_id].raised >= campaigns[_id].cost) {
            campaigns[_id].status = statusEnum.APPROVED;
            balance += campaigns[_id].raised;
            payout(_id);
            return true;
        }

        if (block.timestamp >= campaigns[_id].deadline) {
            campaigns[_id].status = statusEnum.REVERTED;
            refund(_id);
            return true;
        }

        return true;
    }

    function donateToOng (
        uint _id
    ) public payable returns (bool) {

        require(msg.value > 0 ether, "Donation must be greater than 0");
        require(ongExists[_id], "Ong does not exist");
        require(ongs[_id].status == ongStatusEnum.ACTIVE, "Ong closed");

        statistics.totalDonations += msg.value;
        statistics.totalDonators += 1;
        ongs[_id].raised += msg.value;
        ongs[_id].donators += 1;

        donatorsOfOng[_id].push(donatorsStruct(msg.sender, msg.value, block.timestamp, false));

        emit Action(_id, block.timestamp, "Donation to ong", msg.sender);

        balance += ongs[_id].raised;
        payoutOng(_id);
      
        if (ongs[_id].status == ongStatusEnum.DELETED) {
            refund(_id);
            return true;
        }

        return true;
    }
    


    function donationsToCampaign(
        uint _id
    ) public payable{

        uint256 amount = msg.value;
        campaignStruct storage campaign = campaigns[_id];

        campaign.donators += 1;

        statistics.totalDonations += amount;
        statistics.totalDonators += 1;

        donatorsOf[_id].push(donatorsStruct(msg.sender, amount, block.timestamp, false));

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if(sent){
        campaign.raised += amount;
        }
    }

    function donationsToOng (
        uint _id
    ) public payable {

        uint256 amount = msg.value;
        ongStruct storage ong = ongs[_id];

        ong.donators += 1;

        statistics.totalDonations += amount;
        statistics.totalDonators += 1;

        donatorsOfOng[_id].push(donatorsStruct(msg.sender, amount, block.timestamp, false));

        (bool sent, ) = payable(ong.owner).call{value: amount}("");

        if(sent){
        ong.raised += amount;
        }
    }

    function requireRefund(
        uint _id    
    ) public returns(bool){

        require(campaigns[_id].status == statusEnum.REVERTED || campaigns[_id].status == statusEnum.DELETED,
         "Campaign not reverted or deleted");

         campaigns[_id].status = statusEnum.REVERTED;
         refund(_id);

        return true;
    }

    function payoutCampaign (
        uint _id
    ) public returns(bool){

        require(campaigns[_id].status == statusEnum.APPROVED, "Campaign not approved");
        require (msg.sender == campaigns[_id].owner || msg.sender == owner, "Only owner can payout");

        payout(_id);

        return true;
    }

    function changeTax(
        uint _newTax
    ) public ownerOnly{

        campaignTax = _newTax;
        ongTax = _newTax;
    }

    function getCampaign(
        uint _id
    ) public view returns(campaignStruct memory){

        require(campaignExists[_id], "Campaign does not exist");

        return campaigns[_id];
    }

    function getCampaigns() public view returns(campaignStruct[] memory){

        return campaigns;
    }

    function getOng(
        uint _id
    ) public view returns(ongStruct memory){

        require(ongExists[_id], "Ong does not exist");

        return ongs[_id];
    }

    function getOngs() public view returns(ongStruct[] memory){

        return ongs;
    }

    function getDonators(
        uint _id
    ) public view returns(donatorsStruct[] memory){

        return donatorsOf[_id];
    }

    function getDonatorsOng(
        uint _id
    ) public view returns(donatorsStruct[] memory){

        return donatorsOfOng[_id];
    }

    function getStatistics() public view returns(statisticsStruct memory){

        return statistics;
    }

    function getBalance() public view returns(uint){

        return balance;
    }


}