//
//  AdvertisementRow.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import AppleBLEDecoder
import BLETools
import SwiftUI

struct AdvertisementRow: View {
  var advertisement: BLEAdvertisment

  var isDecodedAdvertisement: Bool {
    self.advertisement.advertisementTLV != nil
  }

  var decodedAdvertisements: [DecodedAdvType] {
    let types = self.advertisement.advertisementTypes

    return types.compactMap { (advType) -> DecodedAdvType? in
      guard let advData = self.advertisement.advertisementTLV?.getValue(forType: advType.rawValue)
      else { return nil }

      let decoder = try? AppleBLEDecoding.decoder(forType: UInt8(advType.rawValue))
      let decoded = try? decoder?.decode(advData)

      return DecodedAdvType(type: advType, data: advData, description: decoded)
    }
  }

  var dateFormatter: DateFormatter {
    let df = DateFormatter()
    df.timeStyle = .short
    df.dateStyle = .short

    return df
  }

  var body: some View {
    VStack {
      ForEach(self.decodedAdvertisements) { (decodedAdv) in
        Group {
          DecodedAdvertisementView(decodedAdv: decodedAdv)
        }
      }

      HStack {
        Text("Received \(advertisement.numberOfTimesReceived) times")
        Spacer()
        Text(
          "\(dateFormatter.string(from: advertisement.receptionDates.first!)) - \(dateFormatter.string(from: advertisement.receptionDates.last!))"
        )
      }
    }
  }

  struct DecodedAdvertisementView: View {
    var decodedAdv: DecodedAdvType
    @State var opened = false

    @State var hoveredRange: ClosedRange<UInt>?

    func descriptionView(for advDict: [String: AppleBLEDecoding.DecodedEntry]) -> some View {

      //Map to tuple of (String, DecodedEntry) and sort it by the bytes
      let advDescription = advDict.map { ($0.0, $0.1) }.sorted { (lhs, rhs) -> Bool in
        return lhs.1.byteRange.lowerBound < rhs.1.byteRange.lowerBound
      }

      let keyValues: [(String, String)] = advDescription.map({
        (key: String, value: Any) -> (String, String) in
        if let data = value as? Data {
          return (key, (data.hexadecimal.separate(every: 2, with: " ")))
        }

        if let array = value as? [Any] {
          return (key, array.map { String(describing: $0) }.joined(separator: ", "))
        }

        return (key, String(describing: value))
      })


      return HStack {
        VStack(alignment: .leading) {
          ForEach(
            keyValues, id: \.0,
            content: { keyValue in
              Text("\(keyValue.0): ")
                .font(.system(.body, design: .monospaced))
            })
        }

        VStack(alignment: .leading) {
          ForEach(
            0..<keyValues.count,
            content: { idx in
                Text("\(keyValues[idx].1)")
                  .font(.system(.body, design: .monospaced))
                  .foregroundColor(Color.highlightColor(at: idx))
                  .onTapGesture {
                        self.hoveredRange = advDescription[idx].1.byteRange
                }
            })
        }
      }
    }

    func highlightColorForByte(
      at index: UInt, with advDescription: [(String, AppleBLEDecoding.DecodedEntry)]?
    ) -> Color? {

      //Get the index of the DecodedEntry to get the color for it
      if let idx = advDescription?.enumerated().first(where: {
        $0.element.1.byteRange.contains(index)
      })?.offset {
        return Color.highlightColor(at: idx)
      }

      return nil
    }

    
    /// Sh
    /// - Returns: <#description#>
    func rawDataView() -> some View {
      //Map to tuple of (String, DecodedEntry) and sort it by the bytes
      //Used to get the color index
      let advDescription = self.decodedAdv.description?.map { ($0.0, $0.1) }.sorted {
        (lhs, rhs) -> Bool in
        return lhs.1.byteRange.lowerBound < rhs.1.byteRange.lowerBound
      }

      let byteArray = Array(self.decodedAdv.data)

      return HStack {
        ForEach(0..<byteArray.count) { (idx) in
          Text(String(format: "%02X", byteArray[idx]))
            .foregroundColor(self.highlightColorForByte(at: UInt(idx), with: advDescription))
            .background(self.hoveredRange?.contains(UInt(idx)) == true ? Color.gray : nil)
        }
        Spacer()
      }
    }

    var rowTransition: AnyTransition {
      let insertion = AnyTransition.move(edge: .top).combined(with: .opacity)
      let removal = AnyTransition.move(edge: .top).combined(with: .opacity)

      return .asymmetric(insertion: insertion, removal: removal)
    }

    var body: some View {
      VStack {
        HStack {
          Button(
            action: {
              withAnimation {
                self.opened.toggle()
              }
            },
            label: {
              Image(systemName: "arrowtriangle.right.fill")
                .imageScale(.large)
                .padding(4.0)
                .rotationEffect(Angle(degrees: self.opened ? 90.0 : 0.0))
            }
          )
          .buttonStyle(PlainButtonStyle())
          .padding([.top, .bottom], 2.0)

          HStack {
            Text(decodedAdv.type.description)
              .padding(.leading, 4.0)
            Spacer()
          }
          .padding([.top, .bottom], 2.0)
          .background(Rectangle().fill(Color.lightGray))

        }
        .padding(.trailing, 0)

        if opened {
          Group {

            self.rawDataView()

            if self.decodedAdv.description != nil {
              HStack {
                self.descriptionView(for: self.decodedAdv.description!)
                Spacer()
              }

            }

          }
          .transition(self.rowTransition)

        }
      }
      .edgesIgnoringSafeArea(.trailing)
    }
  }

  struct DecodedAdvType: Identifiable {
    var id: UInt
    var type: BLEAdvertisment.AppleAdvertisementType
    var data: Data
    var description: [String: AppleBLEDecoding.DecodedEntry]?

    init(
      type: BLEAdvertisment.AppleAdvertisementType, data: Data,
      description: [String: AppleBLEDecoding.DecodedEntry]?
    ) {
      self.type = type
      self.data = data
      self.description = description
      self.id = type.rawValue
    }
  }
}

struct AdvertisementRow_Previews: PreviewProvider {
  static var advertisementNearby = try! BLEAdvertisment(
    advertisementData: [
      "kCBAdvDataChannel": 37,
      "kCBAdvDataIsConnectable": true,
      "kCBAdvDataManufacturerData": "0x4c0010054B1CC6E7E6".hexadecimal!,
    ], rssi: NSNumber(value: -30.0))

  static var previews: some View {
    AdvertisementRow(advertisement: self.advertisementNearby)
  }
}
