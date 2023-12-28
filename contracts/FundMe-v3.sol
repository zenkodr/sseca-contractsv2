// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title FundMe Campaign
 * @author ZenKodr
 * @notice Creates crowdfunding campaigns allowing people to donate funds
 */
contract FundMe is ReentrancyGuard, Pausable {
    // Add circuit breaker
    bool public stopped = false;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum CampaignState {
        Active,
        Finished,
        Paused
    }

    // Event for stopping
    event Stopped();

    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        CampaignState state;
    }

    mapping(bytes32 => Campaign) public campaigns;

    uint256 public numberOfCampaigns;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event Paused(bool paused);
    event CampaignDeadlineUpdated(
        bytes32 indexed campaignId,
        uint256 newDeadline
    );
    event CampaignCreated(bytes32 indexed campaignId);
    event Donated(address indexed donator, uint256 amount, bytes32 campaignId);
    event CampaignsReturned(Campaign[] campaigns);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Creates a new campaign
     * @param title Title of campaign
     * @param description Description of campaign
     * @param target Funding target
     * @param deadline Duration of campaign
     * @param image Image URL
     * @return campaignId The ID of the created campaign
     */
    function createCampaign(
        string memory title,
        string memory description,
        uint256 target,
        uint256 deadline,
        string memory image
    ) public onlyOwner nonReentrant whenNotPaused returns (bytes32 campaignId) {
        // Input validation
        require(bytes(title).length >= 3, "Invalid title");
        require(bytes(description).length >= 25, "Invalid description");
        require(bytes(image).length > 0, "The image URL is required");
        require(target > 0.1 ether, "Invalid target");
        require(deadline > block.timestamp, "Invalid deadline");

        campaignId = keccak256(abi.encodePacked(title));

        Campaign storage campaign = campaigns[campaignId];

        // Transfer ownership
        campaign.owner = payable(msg.sender);

        // Set campaign details
        campaign.title = title;
        campaign.description = description;
        campaign.target = target;
        campaign.deadline = deadline;
        campaign.amountCollected = 0;
        campaign.image = image;
        campaign.state = CampaignState.Active;

        // Emit event
        emit CampaignCreated(campaignId);

        numberOfCampaigns = numberOfCampaigns.add(1);
    }

    /**
     * @notice Updates the deadline of a campaign
     * @param campaignId The ID of the campaign
     * @param newDeadline The new deadline of the campaign
     */
    function updateCampaignDeadline(
        bytes32 campaignId,
        uint256 newDeadline
    ) public onlyOwner nonReentrant whenNotPaused {
        require(newDeadline > block.timestamp, "Invalid deadline");

        Campaign storage campaign = campaigns[campaignId];

        // Update deadline
        campaign.deadline = newDeadline;

        // Emit event
        emit CampaignDeadlineUpdated(campaignId, newDeadline);
    }

    /**
     * @notice Donates to a campaign
     * @param campaignId The ID of the campaign
     */
    function donateToCampaign(
        bytes32 campaignId
    ) public payable nonReentrant whenNotPaused {
        // Validate amount
        require(msg.value > 0, "Amount must be greater than 0");

        Campaign storage campaign = campaigns[campaignId];

        // Validate campaign state
        require(campaign.state == CampaignState.Active, "Campaign not active");

        // Transfer funds
        (bool success, ) = campaign.owner.call{value: msg.value}("");
        require(success, "Transfer failed");

        // Emit event
        emit Donated(msg.sender, msg.value, campaignId);
    }

    /**
     * @notice Circuit breaker to stop
     **/

    // Circuit breaker to stop contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;

        if (stopped) {
            emit Stopped();
        }
    }

    modifier stopInEmergency() {
        require(!stopped, "Contract is stopped");
        _;
    }

    /**
     * @notice Gets the campaigns
     * @return campaigns The campaigns
     */
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (
            uint256 campaignId = 0;
            campaignId < numberOfCampaigns;
            campaignId++
        ) {
            Campaign storage campaign = campaigns[bytes32(campaignId)];
            allCampaigns[campaignId] = campaign;
        }

        return allCampaigns;
    }

    /**
     * @notice Pauses the contract
     */
    function pause() public onlyOwner stopInEmergency {
        _pause();

        // Emit event
        emit Paused(true);
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() public onlyOwner stopInEmergency {
        _unpause();

        // Emit event
        emit Paused(false);
    }

    fallback() external payable {
        revert("Direct payments not allowed");
    }

    // receive function to receive Ether
    receive() external payable {
        revert("Direct payments not allowed");
    }
}
