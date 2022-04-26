/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

struct Pair {
    string key;
    string value;
}

struct PageSection {
    address contractInterface;
    uint256 tokenId;
    address contractAddress;
    Pair[] params; // maybe
}

struct PageLayout {
    PageSection[] head; // maybe
    PageSection[] body;
}

struct PageConfig {
    PageLayout layout;
    string published_at;
}

interface IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IWebPageRenderer {
    function tokenHTML(uint256 tokenId) external view returns (string memory);

    function tokenHTML(uint256 tokenId, Pair[] memory params)
        external
        view
        returns (string memory);
}

// TODO: implement ownerOf check
contract WebPageRenderer {
    constructor() {}

    // function renderTokenHTML(address contractAddress, uint256 tokenId)
    //     public
    //     view
    //     returns (string memory)
    // {
    //     IERC721 tokenContract = IERC721(contractAddress);

    //     // TODO: token html
    //     return tokenContract.tokenURI(tokenId);
    // }

    function renderPage(PageConfig memory pageData)
        public
        view
        returns (string memory)
    {
        // PageConfig pageConfig = PageConfig(
        //     PageLayout(
        //         [PageSection(renderTokenFromContract(contractAddress, tokenId))]
        //     )
        // );

        PageLayout memory layout = pageData.layout;

        return renderLayout(layout);
    }

    function renderLayout(PageLayout memory layout)
        public
        view
        returns (string memory)
    {
        // string memory headSectionHtml = renderLayoutSections(layout.head);
        string memory bodySectionHtml = renderLayoutSections(layout.body);

        return bodySectionHtml;
    }

    function renderLayoutSections(PageSection[] memory sections)
        public
        view
        returns (string memory)
    {
        string memory sectionsHtml = "";

        for (uint256 i = 0; i < sections.length; ) {
            string.concat(sectionsHtml, renderPageSection(sections[i]));
        }

        return sectionsHtml;
    }

    function renderPageSection(PageSection memory section)
        public
        view
        returns (string memory)
    {
        // todo: case/switch interface

        // todo: ideally this is just html
        // and we dont parse tokenURI
        // for now going to fake it
        // string tokenURIData = renderTokenFromContract(contractAddress, tokenId);

        IWebPageRenderer sectionContract = IWebPageRenderer(
            section.contractAddress
        );

        uint256 tokenId = section.tokenId;
        string memory tokenHTML = sectionContract.tokenHTML(tokenId);

        return tokenHTML;
    }
}