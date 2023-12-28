// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title FundMe Campaign
 * @author ZenKodr
 * @notice Creates crowdfunding campaigns allowing people to donate funds
 */
contract FundMe is ReentrancyGuard, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  enum CampaignState { Active, Finished, Paused }

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

  event CampaignCreated(bytes32 indexed campaignId);

  event Donated(address indexed donator, uint256 amount, bytes32 campaignId);

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

    campaign.owner = payable(msg.sender);
    campaign.title = title;
    campaign.description = description;
    campaign.target = target;
    campaign.deadline = deadline;
    campaign.amountCollected = 0;
    campaign.image = image;
    campaign.state = CampaignState.Active;

    emit CampaignCreated(campaignId);

    numberOfCampaigns = numberOfCampaigns.add(1);
  }

  /**
   * @notice Updates the deadline of a campaign
   * @param campaignId The ID of the campaign
   * @param newDeadline The new deadline of the campaign
   */
  function updateCampaignDeadline(bytes32 campaignId, uint256 newDeadline) public onlyOwner nonReentrant whenNotPaused {
    require(newDeadline > block.timestamp, "Invalid deadline");

    Campaign storage campaign = campaigns[campaignId];

    campaign.deadline = newDeadline;
  }

  /**
   * @notice Updates the description of a campaign
   * @param campaignId The ID of the campaign
   * @param newDescription The new description of the campaign
   */
  function updateCampaignDescription(bytes32 campaignId, string memory newDescription) public onlyOwner nonReentrant whenNotPaused {
    require(bytes(newDescription).length >= 25, "Invalid description");

    Campaign storage campaign = campaigns[campaignId];

    campaign.description = newDescription;
  }

/**
 * @notice Updates the state of a campaign
 * @param campaignId The ID of the campaign
 * @param newState The new state of the campaign
 */
function updateCampaignState(bytes32 campaignId, CampaignState newState) public onlyOwner nonReentrant whenNotPaused {
  Campaign storage campaign = campaigns[campaignId];

  require(campaign.state != newState, "Campaign is already in the selected state");

  campaign.state = newState;
}

  /**
   * @notice Donates to a campaign
   * @param campaignId The ID of the campaign
   */
  function donateToCampaign(bytes32 campaignId) public payable nonReentrant whenNotPaused {
    require(msg.value > 0, "The amount must be above 0");

    Campaign storage campaign = campaigns[campaignId];

    require(msg.sender != campaign.owner, "Campaign owner cannot donate");
    require(campaign.state == CampaignState.Active, "Campaign is not active");

    campaign.owner.transfer(msg.value); // Transfer the donation to the campaign owner

    emit Donated(msg.sender, msg.value, campaignId);
  }

  /**
   * @notice Gets the list of donators and their donations for a campaign
   * @param campaignId The ID of the campaign
   * @return donators The list of donators
   * @return donations The list of donations
   */
  function getDonators(bytes32 campaignId)
    public
    view
    returns (address[] memory donators, uint256[] memory donations)
  {
    return (campaigns[campaignId].donators, campaigns[campaignId].donations);
  }

  /**
   * @notice Gets all the campaigns
   * @return allCampaigns The list of all campaigns
   */
  function getCampaigns() public view returns (Campaign[] memory allCampaigns) {
    allCampaigns = new Campaign[](numberOfCampaigns);

    for (uint256 i = 0; i < numberOfCampaigns; i++) {
      Campaign storage item = campaigns[bytes32(i)];

      allCampaigns[i] = item;
    }
  }

  /**
   * @notice Pauses the contract
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the contract
   */
  function unpause() public onlyOwner {
    _unpause();
  }
}