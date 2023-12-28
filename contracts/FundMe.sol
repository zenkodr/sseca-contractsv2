// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdFunding is Ownable, ReentrancyGuard {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public onlyOwner nonReentrant returns (uint256) {
        require(
            bytes(_title).length >= 3,
            "The title of atleast 3 characters is required"
        );
        require(
            bytes(_description).length >= 25,
            "The description of atleast 25 characters is required"
        );
        require(bytes(_imageURL).length > 0, "The image URL is required");
        require(
            _targetAmount > 0.1 ether,
            "The target amount must be above 0.1 ether"
        );
        require(
            _deadline > block.timestamp,
            "The deadline must be a future date"
        );
        require(
            numberOfCampaigns < 1000,
            "Too many campaigns, operation costly"
        );

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        emit Action(
            campaign.id,
            "Campaign Created",
            msg.sender,
            block.timestamp
        );

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable nonReentrant {
        require(msg.value > 0, "The amount must be above 0");
        require(
            campaigns[_id].owner != msg.sender,
            "The campaign owner cannot back their own campaign"
        );

        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        campaign.amountCollected += msg.value;

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }

        emit Action(
            campaign._id,
            "Campaign Backed",
            msg.sender,
            block.timestamp
        );
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}