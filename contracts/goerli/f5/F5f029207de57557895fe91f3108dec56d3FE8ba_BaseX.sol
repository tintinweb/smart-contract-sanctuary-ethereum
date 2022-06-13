// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct Organisation { 
    string orgId;
    string name;
}

struct Report { 
    string reportId;
    string orgId;
    string ipfsHash;
    address uploader;
    uint uploadDate;
    uint accountingPeriodStart;
    uint accountingPeriodEnd;

    string sourceURL;
    string title;
    string comments; // THINK: move these fields to IPFS due to their potential size
}

struct Evaluation {
    string evaluationId;
    string orgId;
    string ipfsHash;
    address author;
    uint timestamp;
}

contract BaseX {
    event OrganisationAdded(uint index, string orgId, string name);
    event ReportAdded(uint index, string reportId, string orgId, string ipfsHash, address author, uint accountingPeriodStart, uint accountingPeriodEnd, string sourceURL, string title, string comments);
    event EvaluationAdded(uint index, string evaluationId, string orgId, string ipfsHash, address author);
    
    mapping (string => bool) public guidCollisions; // guids are generated on the front-end, need to ensure they are unique
    // FAIL: Attempt to generate GUID on the smart contract level: https://github.com/pipermerriam/ethereum-uuid/issues/6


    constructor() {
        seedData();
    }

    modifier guidUnique(string memory guid) {
      require(guidCollisions[guid] == false, "guid is not unique");
      guidCollisions[guid] = true;
      _;
   }

    // Seeding data with well known organisation: big tech, oil, environemntal activism, humanitarian, and some contrversial (on purpose, getting some press)
    function seedData() private {
        addOrganisation("8e6111a1-3aa7-4c81-b594-bc843ee3f012", "Google");
        addOrganisation("10ecafed-3a5a-4b5c-b29e-aa97d48c8238", "Tesla");
        addOrganisation("787f1857-8d01-4ebc-a8b0-a8b3f018c7d7", "SpaceX");
        addOrganisation("c632142b-6055-48e1-9b8f-13c824b04644", "Amazon");
        addOrganisation("67a58902-5012-4d20-a30c-ba26dae7a188", "Microsoft");

        addOrganisation("44177a53-a024-4b17-b3bd-7014135427a4", "Shell");
        addOrganisation("4ad27a62-d957-43bb-ace3-91408cd8b83d", "BP");
        addOrganisation("91cd6199-e122-4c8d-a4c9-40844108a770", "Exxon Mobil");
        addOrganisation("5140869a-9779-44c1-af45-7bda9203851b", "Chevron");
        addOrganisation("ab64df41-2e0b-4736-8a20-974f8b6db6c0", "Saudi Aramco");

        addOrganisation("1941adac-b024-4758-929b-ed7bb34b5b6f", "Greenpeace");
        addOrganisation("1d435dff-3405-4f34-b1da-df021f21d85e", "Extinction Rebellion");
        addOrganisation("aed309d7-e350-46e8-96e4-a8bb843dcf6b", "The International Federation of Red Cross and Red Crescent Societies (IFRC)");
        addOrganisation("133bcaf7-cc70-4fa6-8b5e-b9a485851458", "Bill & Melinda Gates Foundation");
        addOrganisation("629a2dba-644a-4e74-ab0a-3f498bd02538", "World Economic Forum");

        addOrganisation("8bac450e-da7f-48e8-8e02-0ff3de1956ba", "Bridgewater Associates");
        addOrganisation("4d059524-0e24-4192-925a-636236ba7ca7", "BlackRock");
        addOrganisation("05558993-4a9f-411b-865f-f778488cb04d", "Renaissance Technologies");
        addOrganisation("d4544e6e-b0fe-4034-9161-0c3e65850ff6", "Palantir");

        addOrganisation("83f3af4a-6d31-4570-8b8d-7cddc0dbade0", "McDonald's");
        addOrganisation("8a13cc8a-2af6-47a6-b09b-b9125386adca", "Coca-Cola");
        addOrganisation("22aab8ca-c2c0-4edd-9583-e11bd064c5d3", "Monsanto");

        addReport("585c0a5c-f6e6-4d98-a8a8-64b7b173330c", "8e6111a1-3aa7-4c81-b594-bc843ee3f012", "QmW2RXnrqbehV6CSswjRmUhGNKWqAZak8LQ5JHxnYXRnrq", 1609459200, 1640995199, "https://www.gstatic.com/gumdrop/sustainability/google-2021-environmental-report.pdf", "Google Environmental Report 2021", "Lorem ipsum...");
        addReport("4dc3744a-e4c8-4100-a8a6-ebfa2b760c85", "c632142b-6055-48e1-9b8f-13c824b04644", "QmTJscoacG5DPqafuJrWxnF1si1smgJDgwJTtGt4S53Bng", 1577836800, 1609459199, "https://sustainability.aboutamazon.com/pdfBuilderDownload?name=amazon-sustainability-2020-reportf", "Amazon Sustainability 2020 Report", "Lorem ipsum...");
        addReport("68548107-a245-47bc-bb4e-4a5862b06d40", "10ecafed-3a5a-4b5c-b29e-aa97d48c8238", "QmPjtsxhqMSKDP7oSakHqKsiCGnJzsuTvKyRdQ7Ek9h5D2", 1577836800, 1609459199, "https://www.tesla.com/ns_videos/2020-tesla-impact-report.pdf", "Tesla Impact Report 2020", "Lorem ipsum...");
    }

    Organisation[] public organisations;
    uint public organisationsLength;

    Evaluation[] public evaluations;
    uint public evaluationsLength;

    Report[] public reports;
    uint public reportsLength;


    function addOrganisation(string memory orgId, string memory name) public guidUnique(orgId) returns (uint) {
        Organisation memory organisation = Organisation(orgId, name);
        organisations.push(organisation);
        emit OrganisationAdded(organisationsLength, orgId, name);
        organisationsLength++;
        return organisationsLength - 1; 
    }

    function addEvaluation(string memory evaluationId, string memory reportId, string memory ipfsHash) public guidUnique(evaluationId) returns (uint) {
        Evaluation memory ev = Evaluation(evaluationId, reportId, ipfsHash, msg.sender, block.timestamp);
        evaluations.push(ev);
        emit EvaluationAdded(evaluationsLength, evaluationId, reportId, ipfsHash, msg.sender);
        evaluationsLength++;
        return evaluationsLength - 1;
    }

    function addReport(string memory reportId, string memory orgId, string memory ipfsHash, uint accountingPeriodStart, uint accountingPeriodEnd, string memory sourceURL, string memory title, string memory comments) public guidUnique(reportId) returns(uint) {
        Report memory report = Report(reportId, orgId, ipfsHash, msg.sender, block.timestamp, accountingPeriodStart, accountingPeriodEnd, sourceURL, title, comments);
        reports.push(report);
        emit ReportAdded(reportsLength, reportId, orgId, ipfsHash, msg.sender, accountingPeriodStart, accountingPeriodEnd, sourceURL, title, comments);
        reportsLength++;
        return reportsLength - 1;
    }


}