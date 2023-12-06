//
//  MapboxDataConverter.swift
//  evcodriver
//
//  Created by Tomek on 2020/09/08.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import CoreLocation
import MapboxCoreNavigation
import MapboxDirections

func getRouteStepProgress(_ stepProgress: RouteStepProgress) -> Dictionary<String, Any> {
  return [
    "distanceTraveled": stepProgress.distanceTraveled,
    "durationRemaining": stepProgress.durationRemaining,
    "fractionTraveled": stepProgress.fractionTraveled,
    "distanceRemaining": stepProgress.distanceRemaining
  ]
}

func getRouteLegProgress(_ legProgress: RouteLegProgress) -> Dictionary<String, Any> {
  return [
    "stepIndex": legProgress.stepIndex,
    "distanceTraveled": legProgress.distanceTraveled,
    "durationRemaining": legProgress.durationRemaining,
    "fractionTraveled": legProgress.fractionTraveled,
    "distanceRemaining": legProgress.distanceRemaining,
    "currentStepProgress": getRouteStepProgress(legProgress.currentStepProgress)
  ]
}

func getRouteProgress(_ progress: RouteProgress) -> Dictionary<String, Any> {
  return [
    "isFinalLeg": progress.isFinalLeg,
    "legIndex": progress.legIndex,
    "distanceTraveled": progress.distanceTraveled,
    "durationRemaining": progress.durationRemaining,
    "fractionTraveled": progress.fractionTraveled,
    "distanceRemaining": progress.distanceRemaining,
    "currentLegProgress": getRouteLegProgress(progress.currentLegProgress)
  ]
}

func getLocation(_ location: CLLocation) -> Dictionary<String, Any> {
  return [
    "latitude": location.coordinate.latitude,
    "longitude": location.coordinate.longitude,
    "accuracyInMeters": location.horizontalAccuracy,
    "speedInMps": location.speed,
    "altitudeInMeters": location.altitude,
    "course": location.course,
  ]
}

func getWaypoint(_ waypoint: Waypoint) -> Dictionary<String, Any> {
  return [
    "latitude": waypoint.coordinate.latitude,
    "longitude": waypoint.coordinate.longitude,
    "name": waypoint.name as Any,
  ]
}
