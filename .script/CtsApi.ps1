<#
.SYNOPSIS
Classes describing types returned by the CTS API

.LINK
https://api.cts-strasbourg.eu/v1/swagger.json
#>

class CtsAnnotatedDestinationStructure {
  [String[]] $DestinationName
  [Int] $DirectionRef
}

class CtsAnnotatedLineStructure {
  [CtsAnnotatedDestinationStructure[]] $Destinations
  [CtsExtensionAnnotatedLineStructure] $Extension
  [String] $LineName
  [String] $LineRef
}

class CtsAnnotatedStopPointStructure {
  [CtsExtensionAnnotatedStopPointStructure] $Extension
  [CtsAnnotatedLineStructure[]] $Lines
  [CtsLocation] $Location
  [String] $StopName
  [String] $StopPointRef
}

class CtsCTSGeneralMessage {
  [String] $ImpactedGroupOfLinesRef
  [String[]] $ImpactedLineRef
  [DateTime] $ImpactEndDateTime
  [DateTime] $ImpactStartDateTime
  [CtsMessage[]] $Message
  [CtsPriority] $Priority
  [Bool] $SendUpdatedNotificationsToCustomers
  [String] $TypeOfPassengerEquipmentRef
}

class CtsError {
  [String] $error
}

class CtsEstimatedCalls {
  [String] $DestinationName
  [String] $DestinationShortName
  [DateTime] $ExpectedArrivalTime
  [DateTime] $ExpectedDepartureTime
  [CtsExtensionEstimatedCalls] $Extension
  [String] $StopPointName
  [String] $StopPointRef
  [String] $Via
}

class CtsEstimatedTimetableDelivery {
  [CtsEstimatedTimetableVersionFrame[]] $EstimatedJourneyVersionFrame
  [DateTime] $ResponseTimestamp
  [String] $ShortestPossibleCycle
  [DateTime] $ValidUntil
  [String] $version
}

class CtsEstimatedTimetableVersionFrame {
  [CtsEstimatedVehicleJourney[]] $EstimatedVehicleJourney
  [DateTime] $RecordedAtTime
}

class CtsEstimatedVehicleJourney {
  [Int] $DirectionRef
  [CtsEstimatedCalls[]] $EstimatedCalls
  [CtsExtensionEstimatedVehicleJourney] $Extension
  [CtsFramedVehicleJourneyRef] $FramedVehicleJourneyRef
  [Bool] $IsCompleteStopSequence
  [String] $LineRef
  [String] $PublishedLineName
}

class CtsExtensionAnnotatedLineStructure {
  [String] $RouteColor
  [String] $RouteTextColor
  [CtsRouteModeEnumeration] $RouteType
}

class CtsExtensionAnnotatedStopPointStructure {
  [Int] $distance
  [Bool] $IsFlexhopStop
  [String] $LogicalStopCode
  [String] $StopCode
}

class CtsExtensionEstimatedCalls {
  [String] $DataSource
  [Bool] $IsCheckOut
  [Bool] $IsRealTime
}

class CtsExtensionEstimatedVehicleJourney {
  [CtsVehicleModeEnumeration] $VehicleMode
}

class CtsExtensionMonitoredCall {
  [String] $DataSource
  [String] $Experimentation
  [Bool] $IsRealTime
}

class CtsFramedVehicleJourneyRef {
  [String] $DatedVehicleJourneySAERef
}

class CtsGeneralMessageDelivery {
  [CtsInfoMessage[]] $InfoMessage
  [DateTime] $ResponseTimestamp
  [String] $ShortestPossibleCycle
  [String] $version
}

class CtsInfoMessage {
  [CtsCTSGeneralMessage] $Content
  [String] $formatRef
  [String] $InfoChannelRef
  [String] $InfoMessageIdentifier
  [String] $ItemIdentifier
  [DateTime] $RecordedAtTime
  [DateTime] $ValidUntilTime
}

enum CtsLang {
  FR
  EN
  DE
}

class CtsLinesDelivery {
  [CtsAnnotatedLineStructure[]] $AnnotatedLineRef
  [String] $RequestMessageRef
  [DateTime] $ResponseTimestamp
  [String] $ShortestPossibleCycle
  [DateTime] $ValidUntil
}

class CtsLineTimetableFile {
  [DateTime] $EndValidity
  [String] $LineName
  [String] $LineRef
  [DateTime] $StartValidity
  [String] $Url
}

class CtsLocation {
  [Double] $Latitude
  [Double] $Longitude
}

class CtsMessage {
  [CtsMessageText[]] $MessageText
  [String] $MessageZoneRef
}

class CtsMessageText {
  [CtsLang] $Lang
  [String] $Value
}

class CtsMonitoredCall {
  [DateTime] $ExpectedArrivalTime
  [DateTime] $ExpectedDepartureTime
  [CtsExtensionMonitoredCall] $Extension
  [Int] $Order
  [String] $StopCode
  [String] $StopPointName
}

class CtsMonitoredStopVisit {
  [CtsMonitoredVehicleJourney] $MonitoredVehicleJourney
  [String] $MonitoringRef
  [DateTime] $RecordedAtTime
  [String] $StopCode
}

class CtsMonitoredVehicleJourney {
  [String] $DestinationName
  [String] $DestinationShortName
  [Int] $DirectionRef
  [CtsFramedVehicleJourneyRef] $FramedVehicleJourneyRef
  [String] $LineRef
  [CtsMonitoredCall] $MonitoredCall
  [CtsOnwardCall[]] $OnwardCall
  [CtsPreviousCall[]] $PreviousCall
  [String] $PublishedLineName
  [CtsVehicleModeEnumeration] $VehicleMode
  [String] $Via
}

class CtsOnwardCall {
  [DateTime] $ExpectedArrivalTime
  [DateTime] $ExpectedDepartureTime
  [Int] $Order
  [String] $StopCode
  [String] $StopPointName
}

class CtsParkAndRide {
  [String] $AccessInformation_DE
  [String] $AccessInformation_EN
  [String] $AccessInformation_FR
  [Int] $AvailableParkingSpots
  [String] $Designation
  [DateTime] $LastUpdate
  [Double] $Latitude
  [Double] $Longitude
  [Bool] $Open
  [Int] $TotalParkingSpots
  [Int] $Variation
}

class CtsPreviousCall {
  [Int] $Order
  [String] $StopCode
  [String] $StopPointName
}

enum CtsPriority {
  Normal
  Urgent
  Extrem
}

class CtsResponseEstimatedTimetableList {
  [CtsServiceDelivery] $ServiceDelivery
}

class CtsResponseGeneralMessageList {
  [CtsServiceDelivery] $ServiceDelivery
}

class CtsResponseLinesDiscoveryList {
  [CtsLinesDelivery] $LinesDelivery
}

class CtsResponseLineTimetablesFilesList {
  [CtsLineTimetableFile[]] $LineTimetablesFiles
}

class CtsResponseParkAndRideList {
  [CtsParkAndRide[]] $ParkAndRide
}

class CtsResponseRetailOutletList {
  [CtsRetailOutlet[]] $RetailOutlet
}

class CtsResponseRetailOutletType {
  [CtsRetailOutletType[]] $RetailOutletType
}

class CtsResponseStopMonitoringList {
  [CtsServiceDelivery] $ServiceDelivery
}

class CtsResponseStopPointsDiscoveryList {
  [CtsStopPointsDelivery] $StopPointsDelivery
}

class CtsResponseStopTimetablesFilesList {
  [CtsStopTimetableFile[]] $TimetablesFiles
}

class CtsResponseVelhopList {
  [CtsVelhop[]] $Velhop
}

class CtsResponseVeloparcList {
  [CtsVeloparc[]] $Veloparc
}

class CtsRetailOutlet {
  [String] $Address
  [Bool] $BadgeoTopUp
  [String] $Designation
  [Double] $Latitude
  [Double] $Longitude
  [String] $OpeningTimes
  [String] $RetailOutletType
  [Int] $RetailOutletTypeId
  [String[]] $Services
  [Bool] $TicketSales
}

class CtsRetailOutletType {
  [Int] $id
  [String] $type
}

enum CtsRouteModeEnumeration {
  bus
  tram
  undefined
}

class CtsServiceDelivery {
  [CtsEstimatedTimetableDelivery[]] $EstimatedTimetableDelivery
  [CtsGeneralMessageDelivery[]] $GeneralMessageDelivery
  [String] $RequestMessageRef
  [DateTime] $ResponseTimestamp
  [CtsStopMonitoringDelivery[]] $StopMonitoringDelivery
  [CtsVehicleMonitoringDelivery[]] $VehicleMonitoringDelivery
}

enum CtsServiceType {
  store
  automaticStation
  storeAndAutomaticStation
}

class CtsStopMonitoringDelivery {
  [CtsMonitoredStopVisit[]] $MonitoredStopVisit
  [String[]] $MonitoringRef
  [DateTime] $ResponseTimestamp
  [String] $ShortestPossibleCycle
  [DateTime] $ValidUntil
  [String] $version
}

class CtsStopPointsDelivery {
  [CtsAnnotatedStopPointStructure[]] $AnnotatedStopPointRef
  [String] $RequestMessageRef
  [DateTime] $ResponseTimestamp
}

class CtsStopTimetableFile {
  [String] $DestinationName
  [DateTime] $EndValidity
  [String] $LineRef
  [DateTime] $StartValidity
  [String] $StopCode
  [String] $Url
}

class CtsVehicleActivity {
  [CtsMonitoredVehicleJourney] $MonitoredVehicleJourney
  [DateTime] $RecordedAtTime
}

enum CtsVehicleModeEnumeration {
  bus
  tram
  coach
  undefined
}

class CtsVehicleMonitoringDelivery {
  [DateTime] $ResponseTimestamp
  [String] $ShortestPossibleCycle
  [DateTime] $ValidUntil
  [CtsVehicleActivity[]] $VehicleActivity
}

class CtsVelhop {
  [String] $AccessInformation_DE
  [String] $AccessInformation_EN
  [String] $AccessInformation_FR
  [Int] $AvailableBikes
  [Int] $AvailableFreeBikeSpots
  [Bool] $BankCard
  [String] $Designation
  [Double] $Latitude
  [Double] $Longitude
  [CtsServiceType] $ServiceType
  [Int] $StationID
  [Int] $TotalBikeSpots
}

class CtsVeloparc {
  [String] $AccessInformation_DE
  [String] $AccessInformation_EN
  [String] $AccessInformation_FR
  [String] $Designation
  [Double] $Latitude
  [Double] $Longitude
}
