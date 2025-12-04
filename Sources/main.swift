import Foundation

struct Period: Codable {
    let start: String
    let end: String
}

struct Company: Codable {
    let name: String
    let legalId: String
    let address: String
    let phone: String?
    let email: String?
}

struct Employee: Codable {
    let id: String
    let name: String
    let position: String
    let monthlyEarnings: [Double]
    let notes: String?
}

struct PayrollInput: Codable {
    let company: Company
    let period: Period
    let employees: [Employee]
}

struct AguinaldoResult {
    let totalEarnings: Double
    let aguinaldo: Double
}

struct CLIOptions {
    let inputPath: String
    let employeeId: String?
    let outputDirectory: String?
}

enum CLIError: Error, CustomStringConvertible {
    case missingInput
    case unableToReadFile(String)
    case unableToDecode(String)
    case employeeNotFound(String)

    var description: String {
        switch self {
        case .missingInput:
            return "Debe indicar la ruta del archivo JSON con --input <ruta>."
        case .unableToReadFile(let path):
            return "No se pudo leer el archivo en la ruta: \(path)."
        case .unableToDecode(let reason):
            return "No se pudo interpretar el archivo JSON. Detalle: \(reason)."
        case .employeeNotFound(let id):
            return "No se encontró el empleado con id \(id)."
        }
    }
}

func parseArguments(_ args: [String]) throws -> CLIOptions {
    var inputPath: String?
    var employeeId: String?
    var outputDirectory: String?

    var index = 0
    while index < args.count {
        let argument = args[index]
        switch argument {
        case "--input":
            index += 1
            if index < args.count {
                inputPath = args[index]
            }
        case "--employee":
            index += 1
            if index < args.count {
                employeeId = args[index]
            }
        case "--output":
            index += 1
            if index < args.count {
                outputDirectory = args[index]
            }
        case "--help", "-h":
            printUsage()
            exit(0)
        default:
            break
        }
        index += 1
    }

    guard let inputPath else {
        throw CLIError.missingInput
    }

    return CLIOptions(inputPath: inputPath, employeeId: employeeId, outputDirectory: outputDirectory)
}

func printUsage() {
    let usage = """
    Uso:
      aguinaldo --input <archivo.json> [--employee <id_empleado>] [--output <directorio>]

    Ejemplos:
      swift run aguinaldo --input Samples/aguinaldo-ejemplo.json
      swift run aguinaldo --input Samples/aguinaldo-ejemplo.json --employee E001 --output recibos

    Si se omite --employee se imprimen los aguinaldos calculados de todos los empleados.
    Al indicar --output se genera un recibo listo para imprimir por cada empleado procesado.
    """
    print(usage)
}

func loadPayroll(from path: String) throws -> PayrollInput {
    let url = URL(fileURLWithPath: path)
    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(PayrollInput.self, from: data)
    } catch let error as DecodingError {
        throw CLIError.unableToDecode(error.localizedDescription)
    } catch {
        throw CLIError.unableToReadFile(path)
    }
}

func calculateAguinaldo(for employee: Employee) -> AguinaldoResult {
    let total = employee.monthlyEarnings.reduce(0, +)
    let aguinaldo = total / 12.0
    return AguinaldoResult(totalEarnings: total, aguinaldo: aguinaldo)
}

func currencyFormatter() -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "es_CR")
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
}

func formatCurrency(_ value: Double) -> String {
    let formatter = currencyFormatter()
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "₡%.2f", value)
}

func printError(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
        try? FileHandle.standardError.write(contentsOf: data)
    }
}

func formatReceipt(for employee: Employee, company: Company, period: Period) -> String {
    let result = calculateAguinaldo(for: employee)
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy"
    let today = formatter.string(from: Date())

    var lines: [String] = []
    lines.append("=================================================================")
    lines.append("\(company.name) | Cédula jurídica: \(company.legalId)")
    lines.append(company.address)
    if let phone = company.phone {
        lines.append("Tel: \(phone)")
    }
    if let email = company.email {
        lines.append("Correo: \(email)")
    }
    lines.append("Periodo de cálculo: \(period.start) al \(period.end)")
    lines.append("Fecha de emisión: \(today)")
    lines.append(String(repeating: "-", count: 65))
    lines.append("Recibo de aguinaldo (Ley Laboral Costa Rica)")
    lines.append("Empleado: \(employee.name) | ID: \(employee.id)")
    lines.append("Puesto: \(employee.position)")
    lines.append(String(repeating: "-", count: 65))

    lines.append("Ingresos considerados en el período:")
    for (index, monthAmount) in employee.monthlyEarnings.enumerated() {
        lines.append(String(format: "  Mes %02d: %@", index + 1, formatCurrency(monthAmount)))
    }

    lines.append(String(repeating: "-", count: 65))
    lines.append("Total devengado: \(formatCurrency(result.totalEarnings))")
    lines.append("Aguinaldo (total/12): \(formatCurrency(result.aguinaldo))")
    if let notes = employee.notes {
        lines.append(String(repeating: "-", count: 65))
        lines.append("Notas: \(notes)")
    }
    lines.append(String(repeating: "-", count: 65))
    lines.append("Firma RRHH: ________________________________")
    lines.append("=================================================================")

    return lines.joined(separator: "\n")
}

func ensureOutputDirectory(_ path: String) throws {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path) {
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
}

func writeReceipt(_ receipt: String, employeeId: String, to directory: String) throws {
    try ensureOutputDirectory(directory)
    let filename = "recibo_aguinaldo_\(employeeId).txt"
    let url = URL(fileURLWithPath: directory).appendingPathComponent(filename)
    try receipt.write(to: url, atomically: true, encoding: .utf8)
    print("Recibo generado en \(url.path)")
}

func processAllEmployees(from payroll: PayrollInput, outputDirectory: String?) {
    for employee in payroll.employees {
        let receipt = formatReceipt(for: employee, company: payroll.company, period: payroll.period)
        print(receipt)
        if let outputDirectory {
            do {
                try writeReceipt(receipt, employeeId: employee.id, to: outputDirectory)
            } catch {
                printError("No se pudo guardar el recibo para \(employee.id): \(error)")
            }
        }
    }
}

func processSingleEmployee(from payroll: PayrollInput, employeeId: String, outputDirectory: String?) throws {
    guard let employee = payroll.employees.first(where: { $0.id == employeeId }) else {
        throw CLIError.employeeNotFound(employeeId)
    }

    let receipt = formatReceipt(for: employee, company: payroll.company, period: payroll.period)
    print(receipt)

    if let outputDirectory {
        try writeReceipt(receipt, employeeId: employee.id, to: outputDirectory)
    }
}

func main() {
    do {
        let options = try parseArguments(Array(CommandLine.arguments.dropFirst()))
        let payroll = try loadPayroll(from: options.inputPath)

        if let employeeId = options.employeeId {
            try processSingleEmployee(from: payroll, employeeId: employeeId, outputDirectory: options.outputDirectory)
        } else {
            processAllEmployees(from: payroll, outputDirectory: options.outputDirectory)
        }
    } catch let error as CLIError {
        printError("Error: \(error.description)")
        printUsage()
        exit(1)
    } catch {
        printError("Error inesperado: \(error.localizedDescription)")
        exit(1)
    }
}

main()
