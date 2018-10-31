package main

import "fmt"
import "log"
import "os"
import "bufio"
import "strings"
import "strconv"

func toString(i float64) string {
  return strconv.FormatFloat(i, 'G', -1, 64)
}

func getMaxInFile(filePath string) (float64, float64, error) {
  inputFile, err := os.Open(filePath)
  if err != nil {
    return 0, 0, err
  }
  defer inputFile.Close()

  maxLatency := 0.0;
  throughput := 0.0;
  toSkip := 3
  scanner := bufio.NewScanner(inputFile)
  for scanner.Scan() {
    if (toSkip > 0) {
      toSkip--;
    } else {
      line := scanner.Text()
      splitted := strings.Split(line, ",")
      latency, err := strconv.ParseFloat(splitted[7], 64)
      if err != nil {
        return 0, 0, err
      }
      throughput, err = strconv.ParseFloat(splitted[4], 64)
      if err != nil {
        return 0, 0, err
      }
      if (latency > maxLatency) {
        maxLatency = latency
      }
      if (latency > 30000) {
        fmt.Println(strings.Join([]string{"Found high latency", toString(latency), "in:", filePath}, " "))
      }
    }
  }
  return maxLatency, throughput, nil
}

type pair struct {
  lat float64
  tp float64
}

func main() {
  success := true
  allowed := make(map[string]pair)
  allowed["insert"] = pair{400.0, 4000.0}
  allowed["get"] = pair{400.0, 8000.0}
  allowed["replace"] = pair{400.0, 2500.0}

  for _, test := range []string{"insert", "get", "replace"} {
    lat, tp, err := getMaxInFile(strings.Join([]string{"/work/outputFiles/", test, ".csv"}, ""))
    if err != nil {
      log.Fatal(err)
    }
    exp := allowed[test]
    if (lat > exp.lat) {
      fmt.Println(strings.Join([]string{"Latency in", test, "is too high, expected:", toString(exp.lat), "got:", toString(lat)}, " "))
      success = false
    }
    if (tp < exp.tp) {
      fmt.Println(strings.Join([]string{"Throughput in", test, "is too low, expected:", toString(exp.tp), "got:", toString(tp)}, " "))
      success = false
    }
  }
  if (!success) {
    log.Fatal("There was at least one case that did not satisfy our requirements, check log output");
  }
}
